import type { Request, Response } from 'express';

import { asyncHandler } from '../../utils/asyncHandler';
import { executeIdempotent } from '../../services/idempotency';
import {
  listCourseSwapRequestsForStudent,
  listMyCourses,
  listMyPayments,
  purchaseCourse,
  requestCourseSwap as createCourseSwapRequestService,
} from './service';

export const buyCourse = asyncHandler(async (req: Request, res: Response) => {
  const result = await executeIdempotent({
    actorId: req.user!.id,
    route: '/api/courses/:id/purchase',
    key: req.get('Idempotency-Key') ?? undefined,
    action: async () => {
      const data = await purchaseCourse(req.user!.id, Number(req.params.id));
      return { status: 200, body: { success: true, data } };
    },
  });
  res.status(result.status).json(result.body);
});

export const myCourses = asyncHandler(async (req: Request, res: Response) => {
  const data = await listMyCourses(req.user!.id);
  res.status(200).json({ success: true, data });
});

export const myPayments = asyncHandler(async (req: Request, res: Response) => {
  const data = await listMyPayments(req.user!.id);
  res.status(200).json({ success: true, data });
});

export const requestCourseSwap = asyncHandler(async (req: Request, res: Response) => {
  const data = await createCourseSwapRequestService(req.user!.id, req.body.old_purchase_id, req.body.new_course_id, req.body.reason ?? null);
  res.status(201).json({ success: true, data });
});

export const myCourseSwapRequests = asyncHandler(async (req: Request, res: Response) => {
  const data = await listCourseSwapRequestsForStudent(req.user!.id);
  res.status(200).json({ success: true, data });
});

