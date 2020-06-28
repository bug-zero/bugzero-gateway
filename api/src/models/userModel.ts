import mongoose, {Schema, Document} from 'mongoose';

export interface IUser extends Document {
    user: string,
    identity: string,
    uuid: string
}

export const UserSchema: Schema = new Schema({
    user: {type: String, required: true},
    identity: {type: String, required: true},
    uuid: {type: String, required: true}
})

export default mongoose.model<IUser>('User', UserSchema);
