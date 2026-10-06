export enum UserRole {
  STUDENT = 'STUDENT',
  TEACHER = 'TEACHER',
  ADMIN = 'ADMIN',
}

export enum LectureType {
  VIDEO = 'VIDEO',
  PDF = 'PDF',
  TEXT = 'TEXT',
}

export enum LectureUploadStatus {
  PENDING = 'PENDING',
  READY = 'READY',
  FAILED = 'FAILED',
}

export enum TopupMethod {
  SHAM_CASH = 'SHAM_CASH',
  TRANSFER_OFFICE = 'TRANSFER_OFFICE',
}

export enum TopupStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export enum TransactionType {
  TOPUP = 'TOPUP',
  PURCHASE = 'PURCHASE',
}
