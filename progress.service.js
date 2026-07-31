"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getEnrollmentProgress = exports.getMyCourseProgress = exports.completeLesson = exports.startLesson = exports.recalculateCourseEnrollments = exports.recalculateEnrollmentProgress = void 0;
const lms_constants_1 = require("../constants/lms.constants");
const AppError_1 = require("../errors/AppError");
const course_model_1 = require("../models/course.model");
const courseSection_model_1 = require("../models/courseSection.model");
const enrollment_model_1 = require("../models/enrollment.model");
const lesson_model_1 = require("../models/lesson.model");
const lessonProgress_model_1 = require("../models/lessonProgress.model");
const quiz_model_1 = require("../models/quiz.model");
const quizAttempt_model_1 = require("../models/quizAttempt.model");
const normalizeMongo_1 = require("../utils/normalizeMongo");
const lmsAccess_service_1 = require("./lmsAccess.service");
const notification_service_1 = require("./notification.service");
const getPublishedLessonIds = async (courseId) => {
    const publishedSectionIds = await courseSection_model_1.CourseSection.find({ courseId, isPublished: true }).distinct('_id');
    if (publishedSectionIds.length === 0)
        return [];
    return lesson_model_1.Lesson.find({
        courseId,
        sectionId: { $in: publishedSectionIds },
        isPublished: true,
    }).distinct('_id');
};
const recalculateEnrollmentProgress = async (enrollmentId) => {
    const enrollment = await enrollment_model_1.Enrollment.findById(enrollmentId);
    if (!enrollment)
        throw new AppError_1.AppError('Enrollment not found', 404, 'ENROLLMENT_NOT_FOUND');
    const publishedLessonIds = await getPublishedLessonIds(enrollment.courseId.toString());
    const totalLessons = publishedLessonIds.length;
    const completedLessons = totalLessons === 0
        ? 0
        : await lessonProgress_model_1.LessonProgress.countDocuments({
            enrollmentId,
            lessonId: { $in: publishedLessonIds },
            status: lms_constants_1.LESSON_PROGRESS_STATUSES.COMPLETED,
        });

    const publishedQuizzes = await quiz_model_1.Quiz.find({ courseId: enrollment.courseId, isPublished: true }).distinct('_id');
    const totalQuizzes = publishedQuizzes.length;
    let completedQuizzes = 0;
    if (totalQuizzes > 0) {
        const passedAttempts = await quizAttempt_model_1.QuizAttempt.find({
            enrollmentId,
            quizId: { $in: publishedQuizzes },
            passed: true,
        }).distinct('quizId');
        completedQuizzes = passedAttempts.length;
    }

    const totalItems = totalLessons + totalQuizzes;
    const completedItems = completedLessons + completedQuizzes;

    const percentage = totalItems === 0 ? 0 : Math.min(100, Math.round((completedItems / totalItems) * 100));
    const wasCompleted = enrollment.status === lms_constants_1.ENROLLMENT_STATUSES.COMPLETED;
    enrollment.progressPercentage = percentage;
    if (percentage === 100 && totalItems > 0) {
        enrollment.status = lms_constants_1.ENROLLMENT_STATUSES.COMPLETED;
        enrollment.completedAt ??= new Date();
    }
    else if (enrollment.status !== lms_constants_1.ENROLLMENT_STATUSES.CANCELLED) {
        enrollment.status = lms_constants_1.ENROLLMENT_STATUSES.ACTIVE;
        enrollment.completedAt = undefined;
    }
    await enrollment.save();
    if (!wasCompleted && enrollment.status === lms_constants_1.ENROLLMENT_STATUSES.COMPLETED) {
        const course = await course_model_1.Course.findById(enrollment.courseId).select('title').lean();
        await (0, notification_service_1.createNotification)({
            userId: enrollment.studentId,
            type: lms_constants_1.NOTIFICATION_TYPES.COURSE_COMPLETED,
            title: 'Course completed',
            message: `You completed ${course?.title ?? 'your course'}.`,
            relatedEntityType: lms_constants_1.RELATED_ENTITY_TYPES.COURSE,
            relatedEntityId: enrollment.courseId,
        });
    }
    return { enrollment, totalLessons, completedLessons, publishedLessonIds };
};
exports.recalculateEnrollmentProgress = recalculateEnrollmentProgress;
const recalculateCourseEnrollments = async (courseId) => {
    const enrollmentIds = await enrollment_model_1.Enrollment.find({
        courseId,
        status: { $ne: lms_constants_1.ENROLLMENT_STATUSES.CANCELLED },
    }).distinct('_id');
    for (const enrollmentId of enrollmentIds) {
        await (0, exports.recalculateEnrollmentProgress)(enrollmentId.toString());
    }
};
exports.recalculateCourseEnrollments = recalculateCourseEnrollments;
const getAccessibleLessonAndEnrollment = async (studentId, lessonId) => {
    const lesson = await lesson_model_1.Lesson.findOne({ _id: lessonId, isPublished: true });
    if (!lesson)
        throw new AppError_1.AppError('Published lesson not found', 404, 'LESSON_NOT_FOUND');
    if (!await courseSection_model_1.CourseSection.exists({ _id: lesson.sectionId, isPublished: true })) {
        throw new AppError_1.AppError('This lesson section is not published', 403, 'SECTION_NOT_PUBLISHED');
    }
    const enrollment = await (0, lmsAccess_service_1.getEnrollmentOrThrow)(studentId, lesson.courseId.toString());
    return { lesson, enrollment };
};
const startLesson = async (studentId, lessonId) => {
    const { lesson, enrollment } = await getAccessibleLessonAndEnrollment(studentId, lessonId);
    const now = new Date();
    const existing = await lessonProgress_model_1.LessonProgress.findOne({ studentId, lessonId });
    const progress = existing ?? new lessonProgress_model_1.LessonProgress({
        studentId,
        lessonId,
        courseId: lesson.courseId,
        enrollmentId: enrollment._id,
    });
    if (progress.status !== lms_constants_1.LESSON_PROGRESS_STATUSES.COMPLETED) {
        progress.status = lms_constants_1.LESSON_PROGRESS_STATUSES.IN_PROGRESS;
        progress.startedAt ??= now;
    }
    progress.lastAccessedAt = now;
    await progress.save();
    enrollment.lastAccessedAt = now;
    await enrollment.save();
    return (0, normalizeMongo_1.normalizeMongo)(progress);
};
exports.startLesson = startLesson;
const completeLesson = async (studentId, lessonId) => {
    const { lesson, enrollment } = await getAccessibleLessonAndEnrollment(studentId, lessonId);
    const now = new Date();
    const progress = await lessonProgress_model_1.LessonProgress.findOne({ studentId, lessonId }) ?? new lessonProgress_model_1.LessonProgress({
        studentId,
        lessonId,
        courseId: lesson.courseId,
        enrollmentId: enrollment._id,
    });
    progress.status = lms_constants_1.LESSON_PROGRESS_STATUSES.COMPLETED;
    progress.startedAt ??= now;
    progress.completedAt = now;
    progress.lastAccessedAt = now;
    await progress.save();
    enrollment.lastAccessedAt = now;
    await enrollment.save();
    const summary = await (0, exports.recalculateEnrollmentProgress)(enrollment.id);
    return {
        lessonProgress: (0, normalizeMongo_1.normalizeMongo)(progress),
        courseProgress: {
            progressPercentage: summary.enrollment.progressPercentage,
            enrollmentStatus: summary.enrollment.status,
            totalLessons: summary.totalLessons,
            completedLessons: summary.completedLessons,
        },
    };
};
exports.completeLesson = completeLesson;
const getMyCourseProgress = async (studentId, courseId) => {
    const enrollment = await (0, lmsAccess_service_1.getEnrollmentOrThrow)(studentId, courseId);
    const publishedSectionIds = await courseSection_model_1.CourseSection.find({ courseId, isPublished: true }).distinct('_id');
    const lessons = await lesson_model_1.Lesson.find({
        courseId,
        sectionId: { $in: publishedSectionIds },
        isPublished: true,
    })
        .populate('sectionId', 'title order')
        .sort({ sectionId: 1, order: 1 })
        .lean();
    const progressRecords = await lessonProgress_model_1.LessonProgress.find({ studentId, courseId }).lean();
    const progressMap = new Map(progressRecords.map((item) => [item.lessonId.toString(), item]));
    return {
        enrollment: (0, normalizeMongo_1.normalizeMongo)(enrollment),
        lessons: (0, normalizeMongo_1.normalizeMongo)(lessons.map((lesson) => ({
            ...lesson,
            progress: progressMap.get(lesson._id.toString()) ?? {
                status: lms_constants_1.LESSON_PROGRESS_STATUSES.NOT_STARTED,
                startedAt: null,
                completedAt: null,
            },
        }))),
    };
};
exports.getMyCourseProgress = getMyCourseProgress;
const getEnrollmentProgress = async (studentId, enrollmentId) => {
    const enrollment = await enrollment_model_1.Enrollment.findOne({ _id: enrollmentId, studentId });
    if (!enrollment)
        throw new AppError_1.AppError('Enrollment not found', 404, 'ENROLLMENT_NOT_FOUND');
    return (0, exports.getMyCourseProgress)(studentId, enrollment.courseId.toString());
};
exports.getEnrollmentProgress = getEnrollmentProgress;
//# sourceMappingURL=progress.service.js.map