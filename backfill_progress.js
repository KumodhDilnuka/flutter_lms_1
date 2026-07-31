const { connectToDatabase, disconnectFromDatabase } = require('./dist/config/database');
const { Enrollment } = require('./dist/models/enrollment.model');
const { recalculateEnrollmentProgress } = require('./dist/services/progress.service');

async function main() {
    try {
        await connectToDatabase();
        console.log('Connected to database');

        const enrollments = await Enrollment.find({});
        console.log(`Found ${enrollments.length} enrollments to recalculate`);

        for (const enrollment of enrollments) {
            try {
                await recalculateEnrollmentProgress(enrollment._id.toString());
                console.log(`Recalculated enrollment ${enrollment._id}, new progress: ${enrollment.progressPercentage}%`);
            } catch (err) {
                console.error(`Error recalculating enrollment ${enrollment._id}:`, err.message);
            }
        }

        console.log('Finished recalculating all enrollments');
        await disconnectFromDatabase();
        process.exit(0);
    } catch (err) {
        console.error('Fatal error:', err);
        process.exit(1);
    }
}

main();
