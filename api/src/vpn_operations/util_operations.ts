import {connectSSH, ssh} from "../utilities/ssh_conn";
import {logger} from "../server";

export namespace VpnUtilOperations {
    export async function getConnectionStatus(): Promise<{ code, signal, stdout, stderr }> {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const command = `sudo ipsec statusall`
        return await ssh.execCommand(command, {cwd: '/'})
    }
}