import { QueryFailedError } from 'typeorm';

import { AppDataSource } from '../../config/data-source';
import { Course } from '../../entities/Course';
import { Purchase } from '../../entities/Purchase';
import { Transaction } from '../../entities/Transaction';
import { TransactionType } from '../../entities/enums';
import { User } from '../../entities/User';
import { AppError } from '../../utils/AppError';
import { calculateMoneyShare, centsToMoney, toCents } from '../../utils/money';
import { notify } from '../notifications/service';

function toPurchasedCourseResponse(purchase: Purchase) {
  return {
    id: purchase.course.id,
    specialization_id: purchase.course.specialization.id,
    teacher_full_name: purchase.course.teacher ? purchase.course.teacher.fullName : null,
    year: purchase.course.year,
    name: purchase.course.name,
    description: purchase.course.description,
    price: purchase.course.price,
    price_paid: purchase.pricePaid,
    teacher_share: purchase.teacherShare,
    source: purchase.source,
    is_granted: purchase.source === 'GRANTED',
    purchased_at: purchase.createdAt,
  };
}

function toPaymentResponse(transaction: Transaction) {
  return {
    id: transaction.id,
    amount: transaction.amount,
    balance_after: transaction.balanceAfter,
    description: transaction.description,
    reference_type: transaction.referenceType,
    reference_id: transaction.referenceId,
    created_at: transaction.createdAt,
  };
}

export async function purchaseCourse(userId: number, courseId: number) {
  try {
    const result = await AppDataSource.transaction(async (manager) => {
      const courseRepository = manager.getRepository(Course);
      const userRepository = manager.getRepository(User);
      const purchaseRepository = manager.getRepository(Purchase);
      const transactionRepository = manager.getRepository(Transaction);

      const course = await courseRepository.findOne({
        where: { id: courseId, isPublished: true, specialization: { isPublished: true } },
        relations: { specialization: true, teacher: true },
      });

      if (!course) {
        throw new AppError(404, 'Course not found');
      }

      const user = await userRepository.findOne({
        where: { id: userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!user) {
        throw new AppError(404, 'User not found');
      }

      const existingPurchase = await purchaseRepository.findOne({
        where: { user: { id: user.id }, course: { id: course.id } },
      });

      if (existingPurchase) {
        throw new AppError(409, 'You already purchased this course');
      }

      if (toCents(user.balance) < toCents(course.price)) {
        throw new AppError(400, 'Insufficient balance');
      }

      const purchase = purchaseRepository.create({
        user: { id: user.id } as User,
        course: { id: course.id } as Course,
        pricePaid: course.price,
        teacher: course.teacher ? ({ id: course.teacher.id } as User) : null,
        teacherShare: course.teacher ? calculateMoneyShare(course.price, course.teacherPercent) : '0.00',
      });
      const savedPurchase = await purchaseRepository.save(purchase);

      const balanceAfter = centsToMoney(toCents(user.balance) - toCents(course.price));
      user.balance = balanceAfter;
      await userRepository.save(user);

      const transaction = transactionRepository.create({
        user: { id: user.id } as User,
        type: TransactionType.PURCHASE,
        amount: course.price,
        balanceAfter,
        description: `Purchased course: ${course.name}`,
        referenceType: 'PURCHASE',
        referenceId: savedPurchase.id,
      });
      await transactionRepository.save(transaction);

      await notify(user.id, 'Purchase successful', `You purchased ${course.name}`, manager);

      return {
        message: 'Course purchased successfully',
        purchase: {
          id: savedPurchase.id,
          course_id: course.id,
          price_paid: savedPurchase.pricePaid,
        },
        balance: balanceAfter,
      };
    });

    return result;
  } catch (error) {
    if (error instanceof QueryFailedError) {
      const driverError = error.driverError as { errno?: number; code?: string } | undefined;
      if (driverError?.errno === 1062 || driverError?.code === 'ER_DUP_ENTRY') {
        throw new AppError(409, 'You already purchased this course');
      }
    }
    throw error;
  }
}

export async function listMyCourses(userId: number) {
  const purchases = await AppDataSource.getRepository(Purchase).find({
    where: { user: { id: userId } },
    relations: { course: { specialization: true, teacher: true } },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return purchases.map(toPurchasedCourseResponse);
}

export async function listMyPayments(userId: number) {
  const transactions = await AppDataSource.getRepository(Transaction).find({
    where: { user: { id: userId }, type: TransactionType.PURCHASE },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return transactions.map(toPaymentResponse);
}
