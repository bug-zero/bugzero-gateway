import mongoose, {Schema, Document} from 'mongoose';

export interface IUser extends Document {
    user: string,
    identity: string,
    uuid: string
}
