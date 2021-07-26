// Copyright 2021 EngFlow Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.Assert;
import org.junit.Test;

public final class DockerNetworkTest {

  private static final String POSTGRESQL_SERVER_IMAGE = "circleci/postgres:9.6-alpine-postgis";

  @Test
  public void dockerNetwork() throws Exception {
    String networkName = System.getenv("HOST_NETWORK_NAME");
    System.out.println(" | DEBUG | Network name: " + networkName);
    Assert.assertFalse(networkName.isEmpty());

    String serverContainerName = "psql-server-" + UUID.randomUUID().toString().substring(0, 5);

    // Start the server.
    new ProcessBuilder(
            "docker",
            "run",
            "--rm",
            "--name=" + serverContainerName,
            "--network=" + networkName,
            POSTGRESQL_SERVER_IMAGE)
        .start();

    // Wait some time for the container to start. 3 seconds is probably enough.
    Thread.sleep(3000);

    // Get the server's address on the docker bridge network.
    String ipAddr = getServerAddr(serverContainerName);
    System.out.println(" | DEBUG | Server address: " + ipAddr);

    // Wait until the server is ready: when it stops replying "Connection refused".
    waitForServer(ipAddr);

    // We expect "psql" to fail, but without a "Connection refused" error.
    Result pingResult = runCommand("psql", "-h", ipAddr);
    Assert.assertEquals(2, pingResult.exitCode);
    Assert.assertFalse(pingResult.stdout.contains("Connection refused"));
    Assert.assertFalse(pingResult.stderr.contains("Connection refused"));
    System.out.println(" | DEBUG | Server replied:");
    System.out.println(pingResult.stdout);
    System.out.println(pingResult.stderr);

    // Kill the server.
    runCommand("docker", "kill", serverContainerName);
  }

  /** Continuously copy ("pump") the |in| stream to the |out| stream. */
  private static Thread pumpStream(InputStream in, ByteArrayOutputStream out) {
    Thread t =
        new Thread(
            () -> {
              byte[] buf = new byte[10000];
              int len;
              try {
                while ((len = in.read(buf)) > 0) {
                  out.write(buf, 0, len);
                }
              } catch (IOException e) {
              }
            });
    t.setDaemon(true);
    t.start();
    return t;
  }

  /** Runs a command as a subprocess and waits until it terminates. */
  private static Result runCommand(String... args) throws Exception {
    Process p =
        new ProcessBuilder(args)
            .redirectInput(ProcessBuilder.Redirect.PIPE)
            .redirectError(ProcessBuilder.Redirect.PIPE)
            .start();
    try (ByteArrayOutputStream out = new ByteArrayOutputStream();
        ByteArrayOutputStream err = new ByteArrayOutputStream()) {
      Thread t1 = pumpStream(p.getInputStream(), out);
      Thread t2 = pumpStream(p.getErrorStream(), err);
      int exit = p.waitFor();
      t1.join();
      t2.join();
      return new Result(exit, out.toByteArray(), err.toByteArray());
    }
  }

  /** Extracts the IP address of |serverContainerName| on the Docker bridge network. */
  private static String getServerAddr(String serverContainerName) throws Exception {
    Result result = runCommand("docker", "exec", serverContainerName, "ip", "a");
    for (String line : result.stdout.split("\n")) {
      if (line.contains("inet 172.") && line.contains("brd")) {
        for (String part : line.split(" ")) {
          if (part.startsWith("172.")) {
            int slash = part.indexOf('/');
            return part.substring(0, slash);
          }
        }
        break;
      }
    }
    throw new Exception("Could not get ip address:\n" + result.stderr);
  }

  /** Runs "psql" against |ipAddr| as long as it keeps replying with "Connection refused". */
  private static void waitForServer(String ipAddr) throws Exception {
    while (true) {
      Result result = runCommand("psql", "-h", ipAddr);
      System.out.println(result.stdout);
      System.out.println(result.stderr);
      boolean running = true;
      for (String line : result.stdout.split("\n")) {
        if (line.contains("Connection refused")) {
          System.out.println(" | DEBUG | Waiting for server...");
          running = false;
          break;
        }
      }
      if (running) {
        System.out.println(" | DEBUG | Server running");
        return;
      } else {
        Thread.sleep(1000);
      }
    }
  }

  private static final class Result {
    final int exitCode;
    final String stdout;
    final String stderr;

    Result(int exitCode, byte[] stdoutBytes, byte[] stderrBytes) {
      this.exitCode = exitCode;
      this.stdout = new String(stdoutBytes, StandardCharsets.UTF_8);
      this.stderr = new String(stderrBytes, StandardCharsets.UTF_8);
    }
  }
}
