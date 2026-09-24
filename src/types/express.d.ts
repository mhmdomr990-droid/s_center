import type { User } from '../entities/User';

declare global {
  namespace Express {
    interface MulterFile {
      fieldname: string;
      originalname: string;
      encoding: string;
      mimetype: string;
      size: number;
      destination: string;
      filename: string;
      path: string;
      buffer: Buffer;
    }

    interface Request {
      user?: User;
      file?: MulterFile;
    }
  }
}

export {};
