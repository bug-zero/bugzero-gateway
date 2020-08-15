import {describe, it} from 'mocha'
import {expect} from 'chai';
import {logger} from "../src/server";
import {connectSSH, ssh} from "../src/utilities/ssh_conn";

describe("ssh connection ", async () => {

    it('should able to execute commands', async function () {
        if (!ssh.connection) {
            await connectSSH()
            logger.info("connected to ssh")
        }
        const result = await ssh.execCommand('ls', {cwd: '/'})
        expect(result.code).eq(null)
    });
})
