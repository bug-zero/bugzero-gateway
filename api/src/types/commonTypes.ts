export class MethodResponse {
    status: number;
    responseMessage: string;
    payload?: any;

    constructor(status: number, responseMessage: string, payload ?: any) {
        this.status = status,
            this.responseMessage = responseMessage;
        this.payload = payload;
    };
}

export enum ResponseStatusCode {
    Okay = 200,
    BadRequest = 400,
    Unauthorized = 401,
    InternalError = 500
}
