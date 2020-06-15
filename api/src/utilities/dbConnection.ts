import mongoose from 'mongoose';

export async function dbConnect() {
    let uri = "mongodb://localhost:27017/test";
    if (!uri) {
        throw new Error('Mongodb uri not defined');
    }
    try {
        await mongoose.connect(uri, {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false});
        console.log('mongodb connection successful');
    } catch (error) {
        console.log(error);
    }

}
