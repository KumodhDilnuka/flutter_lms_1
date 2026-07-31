"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.listQuizAttemptsForInstructor = exports.listMyQuizAttempts = exports.submitQuizAttempt = exports.startQuizAttempt = exports.getStudentQuiz = exports.listStudentQuizzes = exports.publishQuiz = exports.deleteQuizQuestion = exports.updateQuizQuestion = exports.createQuizQuestion = exports.deleteQuiz = exports.updateQuiz = exports.getInstructorQuiz = exports.listInstructorQuizzes = exports.createQuiz = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
const lms_constants_1 = require("../constants/lms.constants");
const AppError_1 = require("../errors/AppError");
const courseSection_model_1 = require("../models/courseSection.model");
const quiz_model_1 = require("../models/quiz.model");
const quizAttempt_model_1 = require("../models/quizAttempt.model");
const quizQuestion_model_1 = require("../models/quizQuestion.model");
const normalizeMongo_1 = require("../utils/normalizeMongo");
const pagination_1 = require("../utils/pagination");
const quiz_validator_1 = require("../validators/quiz.validator");
const lmsAccess_service_1 = require("./lmsAccess.service");
const notification_service_1 = require("./notification.service");
const progress_service_1 = require("./progress.service");
const getOwnedQuiz = async (instructorId, quizId) => {
    const quiz = await quiz_model_1.Quiz.findById(quizId);
    if (!quiz)
        throw new AppError_1.AppError('Quiz not found', 404, 'QUIZ_NOT_FOUND');
    await (0, lmsAccess_service_1.getOwnedCourseOrThrow)(quiz.courseId.toString(), instructorId);
    return quiz;
};
const assertSectionBelongsToCourse = async (sectionId, courseId) => {
    if (!sectionId)
        return;
    const section = await courseSection_model_1.CourseSection.findOne({ _id: sectionId, courseId });
    if (!section) {
        throw new AppError_1.AppError('The selected section does not belong to this course', 422, 'INVALID_COURSE_SECTION');
    }
};
const studentQuestion = (question) => ({
    id: question._id.toString(),
    questionText: question.questionText,
    questionType: question.questionType,
    options: question.options,
    marks: question.marks,
    order: question.order,
});
const createQuiz = async (instructorId, courseId, input) => {
    await (0, lmsAccess_service_1.getOwnedCourseOrThrow)(courseId, instructorId);
    await assertSectionBelongsToCourse(input.sectionId, courseId);
    const quiz = await quiz_model_1.Quiz.create({ courseId, ...input });
    return (0, normalizeMongo_1.normalizeMongo)(quiz);
};
exports.createQuiz = createQuiz;
const listInstructorQuizzes = async (instructorId, courseId) => {
    await (0, lmsAccess_service_1.getOwnedCourseOrThrow)(courseId, instructorId);
    const quizzes = await quiz_model_1.Quiz.find({ courseId }).populate('sectionId', 'title order').sort({ createdAt: -1 }).lean();
    const questionCounts = await quizQuestion_model_1.QuizQuestion.aggregate([
        { $match: { quizId: { $in: quizzes.map((quiz) => quiz._id) } } },
        { $group: { _id: '$quizId', count: { $sum: 1 } } },
    ]);
    const countMap = new Map(questionCounts.map((item) => [item._id.toString(), item.count]));
    return (0, normalizeMongo_1.normalizeMongo)(quizzes.map((quiz) => ({ ...quiz, questionCount: countMap.get(quiz._id.toString()) ?? 0 })));
};
exports.listInstructorQuizzes = listInstructorQuizzes;
const getInstructorQuiz = async (instructorId, quizId) => {
    const quiz = await getOwnedQuiz(instructorId, quizId);
    const questions = await quizQuestion_model_1.QuizQuestion.find({ quizId }).sort({ order: 1 }).lean();
    return { quiz: (0, normalizeMongo_1.normalizeMongo)(quiz), questions: (0, normalizeMongo_1.normalizeMongo)(questions) };
};
exports.getInstructorQuiz = getInstructorQuiz;
const updateQuiz = async (instructorId, quizId, input) => {
    const quiz = await getOwnedQuiz(instructorId, quizId);
    if (quiz.isPublished) {
        throw new AppError_1.AppError('Unpublish is not supported; published quiz settings cannot be edited', 409, 'QUIZ_ALREADY_PUBLISHED');
    }
    if (input.sectionId !== undefined) {
        await assertSectionBelongsToCourse(input.sectionId, quiz.courseId.toString());
        quiz.sectionId = input.sectionId ? new mongoose_1.default.Types.ObjectId(input.sectionId) : undefined;
    }
    if (input.title !== undefined)
        quiz.title = input.title;
    if (input.description !== undefined)
        quiz.description = input.description;
    if (input.passingScore !== undefined)
        quiz.passingScore = input.passingScore;
    if (input.timeLimitMinutes !== undefined)
        quiz.timeLimitMinutes = input.timeLimitMinutes;
    if (input.maxAttempts !== undefined)
        quiz.maxAttempts = input.maxAttempts;
    await quiz.save();
    return (0, normalizeMongo_1.normalizeMongo)(quiz);
};
exports.updateQuiz = updateQuiz;
const deleteQuiz = async (instructorId, quizId) => {
    const quiz = await getOwnedQuiz(instructorId, quizId);
    if (quiz.isPublished && await quizAttempt_model_1.QuizAttempt.exists({ quizId })) {
        throw new AppError_1.AppError('A published quiz with attempts cannot be deleted', 409, 'QUIZ_HAS_ATTEMPTS');
    }
    await Promise.all([
        quizQuestion_model_1.QuizQuestion.deleteMany({ quizId }),
        quizAttempt_model_1.QuizAttempt.deleteMany({ quizId }),
        quiz_model_1.Quiz.deleteOne({ _id: quizId }),
    ]);
};
exports.deleteQuiz = deleteQuiz;
const createQuizQuestion = async (instructorId, quizId, input) => {
    const quiz = await getOwnedQuiz(instructorId, quizId);
    if (quiz.isPublished)
        throw new AppError_1.AppError('Questions cannot be changed after publishing', 409, 'QUIZ_ALREADY_PUBLISHED');
    const lastQuestion = await quizQuestion_model_1.QuizQuestion.findOne({ quizId }).sort({ order: -1 }).select('order').lean();
    const question = await quizQuestion_model_1.QuizQuestion.create({ quizId, ...input, order: (lastQuestion?.order ?? 0) + 1 });
    return (0, normalizeMongo_1.normalizeMongo)(question);
};
exports.createQuizQuestion = createQuizQuestion;
const updateQuizQuestion = async (instructorId, questionId, input) => {
    const question = await quizQuestion_model_1.QuizQuestion.findById(questionId);
    if (!question)
        throw new AppError_1.AppError('Quiz question not found', 404, 'QUIZ_QUESTION_NOT_FOUND');
    const quiz = await getOwnedQuiz(instructorId, question.quizId.toString());
    if (quiz.isPublished)
        throw new AppError_1.AppError('Questions cannot be changed after publishing', 409, 'QUIZ_ALREADY_PUBLISHED');
    const merged = quiz_validator_1.createQuizQuestionBodySchema.parse({
        questionText: input.questionText ?? question.questionText,
        questionType: input.questionType ?? question.questionType,
        options: input.options ?? question.options.map((option) => ({ id: option.id, text: option.text })),
        correctOptionIds: input.correctOptionIds ?? question.correctOptionIds,
        marks: input.marks ?? question.marks,
    });
    question.set(merged);
    await question.save();
    return (0, normalizeMongo_1.normalizeMongo)(question);
};
exports.updateQuizQuestion = updateQuizQuestion;
const deleteQuizQuestion = async (instructorId, questionId) => {
    const question = await quizQuestion_model_1.QuizQuestion.findById(questionId);
    if (!question)
        throw new AppError_1.AppError('Quiz question not found', 404, 'QUIZ_QUESTION_NOT_FOUND');
    const quiz = await getOwnedQuiz(instructorId, question.quizId.toString());
    if (quiz.isPublished)
        throw new AppError_1.AppError('Questions cannot be changed after publishing', 409, 'QUIZ_ALREADY_PUBLISHED');
    await question.deleteOne();
    const remaining = await quizQuestion_model_1.QuizQuestion.find({ quizId: quiz._id }).sort({ order: 1 }).select('_id').lean();
    if (remaining.length > 0) {
        await quizQuestion_model_1.QuizQuestion.bulkWrite(remaining.map((item, index) => ({
            updateOne: { filter: { _id: item._id }, update: { $set: { order: index + 1 } } },
        })));
    }
};
exports.deleteQuizQuestion = deleteQuizQuestion;
const publishQuiz = async (instructorId, quizId) => {
    const quiz = await getOwnedQuiz(instructorId, quizId);
    if (quiz.isPublished)
        return (0, normalizeMongo_1.normalizeMongo)(quiz);
    if (quiz.sectionId && !await courseSection_model_1.CourseSection.exists({ _id: quiz.sectionId, isPublished: true })) {
        throw new AppError_1.AppError('Publish the selected course section before publishing this quiz', 409, 'SECTION_NOT_PUBLISHED');
    }
    if (!await quizQuestion_model_1.QuizQuestion.exists({ quizId })) {
        throw new AppError_1.AppError('Add at least one question before publishing the quiz', 409, 'QUIZ_QUESTION_REQUIRED');
    }
    quiz.isPublished = true;
    await quiz.save();
    return (0, normalizeMongo_1.normalizeMongo)(quiz);
};
exports.publishQuiz = publishQuiz;
const listStudentQuizzes = async (studentId, courseId) => {
    await (0, lmsAccess_service_1.getEnrollmentOrThrow)(studentId, courseId);
    const publishedSectionIds = await courseSection_model_1.CourseSection.find({ courseId, isPublished: true }).distinct('_id');
    const quizzes = await quiz_model_1.Quiz.find({
        courseId,
        isPublished: true,
        $or: [
            { sectionId: { $exists: false } },
            { sectionId: null },
            { sectionId: { $in: publishedSectionIds } },
        ],
    })
        .populate('sectionId', 'title order isPublished')
        .sort({ createdAt: 1 })
        .lean();
    return (0, normalizeMongo_1.normalizeMongo)(quizzes);
};
exports.listStudentQuizzes = listStudentQuizzes;
const getStudentQuiz = async (studentId, quizId) => {
    const quiz = await quiz_model_1.Quiz.findOne({ _id: quizId, isPublished: true }).lean();
    if (!quiz)
        throw new AppError_1.AppError('Published quiz not found', 404, 'QUIZ_NOT_FOUND');
    await (0, lmsAccess_service_1.getEnrollmentOrThrow)(studentId, quiz.courseId.toString());
    if (quiz.sectionId && !await courseSection_model_1.CourseSection.exists({ _id: quiz.sectionId, isPublished: true })) {
        throw new AppError_1.AppError('This quiz section is not published', 403, 'SECTION_NOT_PUBLISHED');
    }
    const questions = await quizQuestion_model_1.QuizQuestion.find({ quizId }).sort({ order: 1 }).lean();
    return {
        quiz: (0, normalizeMongo_1.normalizeMongo)(quiz),
        questions: questions.map(studentQuestion),
    };
};
exports.getStudentQuiz = getStudentQuiz;
const startQuizAttempt = async (studentId, quizId) => {
    const quiz = await quiz_model_1.Quiz.findOne({ _id: quizId, isPublished: true });
    if (!quiz)
        throw new AppError_1.AppError('Published quiz not found', 404, 'QUIZ_NOT_FOUND');
    const enrollment = await (0, lmsAccess_service_1.getEnrollmentOrThrow)(studentId, quiz.courseId.toString());
    const activeAttempt = await quizAttempt_model_1.QuizAttempt.findOne({ quizId, studentId, status: lms_constants_1.QUIZ_ATTEMPT_STATUSES.IN_PROGRESS });
    if (activeAttempt) {
        const expired = quiz.timeLimitMinutes > 0 &&
            Date.now() > activeAttempt.startedAt.getTime() + (quiz.timeLimitMinutes * 60 * 1000) + 30000;
        if (!expired) {
            throw new AppError_1.AppError('You already have an active attempt for this quiz', 409, 'QUIZ_ATTEMPT_ALREADY_ACTIVE');
        }
        const totalMarks = await quizQuestion_model_1.QuizQuestion.aggregate([
            { $match: { quizId: quiz._id } },
            { $group: { _id: null, total: { $sum: '$marks' } } },
        ]);
        activeAttempt.answers = [];
        activeAttempt.score = 0;
        activeAttempt.totalMarks = totalMarks[0]?.total ?? 0;
        activeAttempt.percentage = 0;
        activeAttempt.passed = false;
        activeAttempt.status = lms_constants_1.QUIZ_ATTEMPT_STATUSES.SUBMITTED;
        activeAttempt.submittedAt = new Date();
        await activeAttempt.save();
    }
    const previousAttempts = await quizAttempt_model_1.QuizAttempt.countDocuments({ quizId, studentId, status: lms_constants_1.QUIZ_ATTEMPT_STATUSES.SUBMITTED });
    if (previousAttempts >= quiz.maxAttempts) {
        throw new AppError_1.AppError('The maximum number of quiz attempts has been reached', 409, 'MAX_QUIZ_ATTEMPTS_REACHED');
    }
    const attempt = await quizAttempt_model_1.QuizAttempt.create({
        quizId,
        studentId,
        enrollmentId: enrollment._id,
        attemptNumber: previousAttempts + 1,
    });
    return (0, normalizeMongo_1.normalizeMongo)(attempt);
};
exports.startQuizAttempt = startQuizAttempt;
const equalAnswerSets = (left, right) => {
    const a = [...new Set(left)].sort();
    const b = [...new Set(right)].sort();
    return a.length === b.length && a.every((value, index) => value === b[index]);
};
const submitQuizAttempt = async (studentId, attemptId, input) => {
    const attempt = await quizAttempt_model_1.QuizAttempt.findOne({ _id: attemptId, studentId });
    if (!attempt)
        throw new AppError_1.AppError('Quiz attempt not found', 404, 'QUIZ_ATTEMPT_NOT_FOUND');
    if (attempt.status === lms_constants_1.QUIZ_ATTEMPT_STATUSES.SUBMITTED) {
        throw new AppError_1.AppError('This quiz attempt has already been submitted', 409, 'QUIZ_ATTEMPT_ALREADY_SUBMITTED');
    }
    const quiz = await quiz_model_1.Quiz.findById(attempt.quizId);
    if (!quiz)
        throw new AppError_1.AppError('Quiz not found', 404, 'QUIZ_NOT_FOUND');
    const questions = await quizQuestion_model_1.QuizQuestion.find({ quizId: quiz._id }).sort({ order: 1 });
    if (questions.length === 0)
        throw new AppError_1.AppError('This quiz has no questions', 409, 'QUIZ_HAS_NO_QUESTIONS');
    const submittedQuestionIds = input.answers.map((answer) => answer.questionId);
    if (new Set(submittedQuestionIds).size !== submittedQuestionIds.length) {
        throw new AppError_1.AppError('A quiz question can be answered only once', 422, 'DUPLICATE_QUIZ_ANSWER');
    }
    const questionMap = new Map(questions.map((question) => [question.id, question]));
    for (const answer of input.answers) {
        const question = questionMap.get(answer.questionId);
        if (!question) {
            throw new AppError_1.AppError('An answer references a question outside this quiz', 422, 'INVALID_QUIZ_QUESTION');
        }
        const selectedIds = [...new Set(answer.selectedOptionIds)];
        if (selectedIds.length !== answer.selectedOptionIds.length) {
            throw new AppError_1.AppError('Selected option IDs must be unique', 422, 'DUPLICATE_SELECTED_OPTION');
        }
        const validOptionIds = new Set(question.options.map((option) => option.id));
        if (selectedIds.some((id) => !validOptionIds.has(id))) {
            throw new AppError_1.AppError('An answer contains an invalid option', 422, 'INVALID_QUIZ_OPTION');
        }
        if ((question.questionType === lms_constants_1.QUIZ_QUESTION_TYPES.SINGLE_CHOICE ||
            question.questionType === lms_constants_1.QUIZ_QUESTION_TYPES.TRUE_FALSE) &&
            selectedIds.length > 1) {
            throw new AppError_1.AppError('This question accepts only one option', 422, 'MULTIPLE_OPTIONS_NOT_ALLOWED');
        }
    }
    const timedOut = quiz.timeLimitMinutes > 0 &&
        Date.now() > attempt.startedAt.getTime() + (quiz.timeLimitMinutes * 60 * 1000) + 30000;
    const answerMap = new Map((timedOut ? [] : input.answers).map((answer) => [answer.questionId, answer.selectedOptionIds]));
    let score = 0;
    let totalMarks = 0;
    for (const question of questions) {
        totalMarks += question.marks;
        const selected = answerMap.get(question.id) ?? [];
        if (equalAnswerSets(selected, question.correctOptionIds))
            score += question.marks;
    }
    const percentage = totalMarks === 0 ? 0 : Math.round((score / totalMarks) * 10000) / 100;
    attempt.answers = (timedOut ? [] : input.answers).map((answer) => ({
        questionId: new mongoose_1.default.Types.ObjectId(answer.questionId),
        selectedOptionIds: answer.selectedOptionIds,
    }));
    attempt.score = score;
    attempt.totalMarks = totalMarks;
    attempt.percentage = percentage;
    attempt.passed = percentage >= quiz.passingScore;
    attempt.status = lms_constants_1.QUIZ_ATTEMPT_STATUSES.SUBMITTED;
    attempt.submittedAt = new Date();
    await attempt.save();
    await (0, progress_service_1.recalculateEnrollmentProgress)(attempt.enrollmentId.toString());
    await (0, notification_service_1.createNotification)({
        userId: studentId,
        type: lms_constants_1.NOTIFICATION_TYPES.QUIZ_RESULT,
        title: 'Quiz result available',
        message: timedOut
            ? `Your attempt for ${quiz.title} expired and was submitted with 0%.`
            : `You scored ${percentage}% for ${quiz.title}.`,
        relatedEntityType: lms_constants_1.RELATED_ENTITY_TYPES.QUIZ_ATTEMPT,
        relatedEntityId: attempt._id,
    });
    return {
        attempt: (0, normalizeMongo_1.normalizeMongo)(attempt),
        result: {
            score,
            totalMarks,
            percentage,
            passed: attempt.passed,
            passingScore: quiz.passingScore,
            timedOut,
        },
    };
};
exports.submitQuizAttempt = submitQuizAttempt;
const listMyQuizAttempts = async (studentId, quizId, page, limit) => {
    const pagination = (0, pagination_1.getPagination)({ page, limit });
    const [attempts, totalItems] = await Promise.all([
        quizAttempt_model_1.QuizAttempt.find({ quizId, studentId }).sort({ attemptNumber: -1 }).skip(pagination.skip).limit(pagination.limit).lean(),
        quizAttempt_model_1.QuizAttempt.countDocuments({ quizId, studentId }),
    ]);
    return { attempts: (0, normalizeMongo_1.normalizeMongo)(attempts), pagination: (0, pagination_1.createPaginationMetadata)(page, limit, totalItems) };
};
exports.listMyQuizAttempts = listMyQuizAttempts;
const listQuizAttemptsForInstructor = async (instructorId, quizId, page, limit) => {
    await getOwnedQuiz(instructorId, quizId);
    const pagination = (0, pagination_1.getPagination)({ page, limit });
    const [attempts, totalItems] = await Promise.all([
        quizAttempt_model_1.QuizAttempt.find({ quizId }).populate('studentId', 'firstName lastName email').sort({ submittedAt: -1 }).skip(pagination.skip).limit(pagination.limit).lean(),
        quizAttempt_model_1.QuizAttempt.countDocuments({ quizId }),
    ]);
    return { attempts: (0, normalizeMongo_1.normalizeMongo)(attempts), pagination: (0, pagination_1.createPaginationMetadata)(page, limit, totalItems) };
};
exports.listQuizAttemptsForInstructor = listQuizAttemptsForInstructor;
//# sourceMappingURL=quiz.service.js.map