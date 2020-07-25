import {logger} from "../server";
import {connectSSH, ssh} from "../utilities/ssh_conn";

const lockFile = '/ipseclock'

export namespace VpnUserOperations {

    export async function execTest(): Promise<any> {

        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        return await ssh.execCommand('sudo sleep 5', {cwd: '/home'})

    }

    export async function addUser(username, secret): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }

        const command = `flock -x ${lockFile} echo '${username} : EAP "${secret}"' | sudo tee -a /etc/ipsec.secrets`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function getAllUsers(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        return await ssh.execCommand(`sudo flock -s ${lockFile} cat /etc/ipsec.secrets`, {cwd: '/'})
    }

    export async function deleteUser(username): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }

        const command = `sudo flock -x ${lockFile} sed -i '/${username} .*/d' /etc/ipsec.secrets`
        return await ssh.execCommand(command, {cwd: '/'})
    }

    export async function updateUser(username, secret): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }

        const command = `sudo flock -x ${lockFile} sed -i 's/${username} .*/${username} : EAP "${secret}"/' /etc/ipsec.secrets`
        return await ssh.execCommand(command, {cwd: '/'})
    }

}
