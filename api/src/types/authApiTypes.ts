export interface GeneralUserRegistrationParams {
    user: string,
    identity: string,

}

export interface LoginParameters {
    email: string,
    password: string
}

export interface JWTtokenCreateParameters {
    _id: string,
    uuid: string
}

export interface JWTtokenReturnParameters {
    uuid: string,
    createdDate: number
}
