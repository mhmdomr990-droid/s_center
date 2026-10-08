import assert from 'node:assert/strict';
import { PurchaseSource } from '../src/entities/enums';
import { calculateCourseSwapBalanceDelta, evaluateCourseSwapRequest, resolveSwapReplacementPurchaseFields } from '../src/modules/purchase/service';

const now = new Date();

const allowed = evaluateCourseSwapRequest({
  purchaseCreatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 12),
  currentCourseId: 1,
  replacementCourseId: 2,
  allowedWindowHours: 72,
});
assert.equal(allowed.allowed, true, 'Swap should be allowed within the allowed window');
assert.equal(allowed.reason, null, 'Reason should be empty when allowed');

const tooOld = evaluateCourseSwapRequest({
  purchaseCreatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 10),
  currentCourseId: 1,
  replacementCourseId: 2,
  allowedWindowHours: 72,
});
assert.equal(tooOld.allowed, false, 'Swap should be blocked after the allowed window');
assert.match(tooOld.reason ?? '', /نافذة/i, 'Reason should mention the time window');

const sameCourse = evaluateCourseSwapRequest({
  purchaseCreatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 3),
  currentCourseId: 5,
  replacementCourseId: 5,
  allowedWindowHours: 72,
});
assert.equal(sameCourse.allowed, false, 'Same course cannot be requested as a replacement');

const freeSwap = resolveSwapReplacementPurchaseFields({
  oldSource: PurchaseSource.GRANTED,
  replacementPrice: '250.00',
  replacementTeacherShare: '62.50',
});
assert.equal(freeSwap.source, PurchaseSource.GRANTED, 'Free-grant swaps remain free-grants');
assert.equal(freeSwap.pricePaid, '0.00', 'Free-grant swaps must not create paid value');
assert.equal(freeSwap.teacherShare, '0.00', 'Free-grant swaps must not create teacher revenue');

const paidSwap = resolveSwapReplacementPurchaseFields({
  oldSource: PurchaseSource.PURCHASED,
  replacementPrice: '250.00',
  replacementTeacherShare: '62.50',
});
assert.equal(paidSwap.source, PurchaseSource.PURCHASED, 'Purchased swaps remain paid purchases');
assert.equal(paidSwap.pricePaid, '250.00', 'Paid swaps should carry the replacement course price');
assert.equal(paidSwap.teacherShare, '62.50', 'Paid swaps should keep the replacement teacher share');

const priceIncreaseDelta = calculateCourseSwapBalanceDelta({ oldCoursePrice: '180.00', newCoursePrice: '250.00' });
assert.equal(priceIncreaseDelta.deltaCents, 7000n, 'A more expensive replacement course should create a positive charge');
assert.equal(priceIncreaseDelta.direction, 'charge', 'A positive delta means the student must be charged');

const refundDelta = calculateCourseSwapBalanceDelta({ oldCoursePrice: '250.00', newCoursePrice: '180.00' });
assert.equal(refundDelta.deltaCents, 7000n, 'A cheaper replacement course should create a refund for the difference');
assert.equal(refundDelta.direction, 'refund', 'A negative delta means the student should receive a refund');

console.log('course-swap tests passed');
