import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { validate } from '../../middlewares/validate';
import { courseSwapRequestSchema, purchaseCourseParamSchema } from './schemas';
import { buyCourse, myCourses, myCourseSwapRequests, myPayments, requestCourseSwap } from './controller';

export const purchaseRoutes = Router();

purchaseRoutes.post('/courses/:id/purchase', authMiddleware, validate({ params: purchaseCourseParamSchema }), buyCourse);
purchaseRoutes.get('/me/courses', authMiddleware, myCourses);
purchaseRoutes.get('/me/payments', authMiddleware, myPayments);
purchaseRoutes.post('/course-swap-requests', authMiddleware, validate({ body: courseSwapRequestSchema }), requestCourseSwap);
purchaseRoutes.get('/course-swap-requests', authMiddleware, myCourseSwapRequests);
