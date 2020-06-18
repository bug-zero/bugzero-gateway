import User, { IUser } from "../models/userModel"
import { MethodResponse, ResponseStatusCode } from "../types/commonTypes";
import { v4 as uuid } from 'uuid';
import {GeneralUserRegistrationParams} from "../types/authApiTypes";

export class UserController {


    public static async findUser(userId: string): Promise<MethodResponse> {
        try {
            let user = await User.findById(userId);
            if (!user) {
                return new MethodResponse(ResponseStatusCode.BadRequest, 'User not found');
            }
            return new MethodResponse(ResponseStatusCode.Okay, 'okay', user);
        } catch (why) {
            return new MethodResponse(ResponseStatusCode.InternalError, why)
        }
    }

    public static async getAllUsers(): Promise<MethodResponse> {
        try {
            let users = await User.find({}).select('user identity');
            return new MethodResponse(ResponseStatusCode.Okay, 'okay', users);
        } catch (why) {
            return new MethodResponse(ResponseStatusCode.InternalError, why);
        }
    }

    public static async addUser(userInfo: GeneralUserRegistrationParams) : Promise<MethodResponse>{
        try {
            let isDuplicate = await User.exists({ user: userInfo.user });
            if (isDuplicate) {
                return new MethodResponse(ResponseStatusCode.BadRequest, 'The user already exists');
            }
            const _uuid: string = uuid();
            const newUser: IUser = new User({
                user: userInfo.user,
                identity: userInfo.identity,
                uuid: _uuid
            });
            await newUser.save();
            return new MethodResponse(ResponseStatusCode.Okay, 'okay')
            // try {
            //     let jwtToken = await createJWT({
            //         _id : newUser._id,
            //         uuid: newUser.uuid
            //     });
            //     return new MethodResponse(ResponseStatusCode.Okay, 'okay', jwtToken);
            // } catch (why) {
            //     return new MethodResponse(ResponseStatusCode.InternalError, why)
            // }
        } catch(why) {
            return new MethodResponse(ResponseStatusCode.InternalError, why)
        }
    }
}

