import NodeSSH from "node-ssh";

export const ssh = new NodeSSH()


export async function connectSSH() {

    if (process.env.SSH_USE_PASSWORD === '1')
        await ssh.connect({
            host: process.env.SSH_HOST,
            username: process.env.SSH_USERNAME,
            password: process.env.SSH_PASSWORD
        })
    else {

        if (!process.env.SSH_PRIVATE_KEY) {
            throw new Error("You should provide private key to connect ssh")
        }

        const data = process.env.SSH_PRIVATE_KEY
        if (data) {
            let buff = Buffer.from(data, 'base64');
            const privateKey = buff.toString();

            await ssh.connect({
                host: process.env.SSH_HOST,
                username: process.env.SSH_USERNAME,
                privateKey: privateKey
            })
        }


    }
}
