package com.engflow.notificationqueue;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

public class NotificationOptions {
  Options options = new Options();
  CommandLineParser parser = new DefaultParser();
  CommandLine cmd;

  public NotificationOptions() {}

  public NotificationOptions parseOptions(String[] args) {
    instantiateOptions();
    try {
      cmd = parser.parse(options, args);
    } catch (ParseException e) {
      throw new IllegalArgumentException(e);
    }

    if (cmd.hasOption("queue_name") && cmd.hasOption("notification_queue_endpoint")) {
      return this;
    } else {
      throw new IllegalArgumentException("Please provide the arguments...");
    }
  }

  public String getOption(String value) {
    return cmd.getOptionValue(value);
  }

  private void instantiateOptions() {
    Option queueName =
        Option.builder()
            .longOpt("queue_name")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc("The name of the queue that you want to receive notifications from.")
            .build();
    options.addOption(queueName);

    Option endpoint =
        Option.builder()
            .longOpt("notification_queue_endpoint")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc(
                "The service endpoint in protocol://host:port format. The protocol must be 'grpc'"
                    + " or 'grpcs' signifying plaintext or TLS-encrypted communication"
                    + " respectively.")
            .build();
    options.addOption(endpoint);

    Option certificate =
        Option.builder()
            .longOpt("tls_certificate")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc("The path of the mTLS certificate to use as the client certificate.")
            .build();
    options.addOption(certificate);

    Option key =
        Option.builder()
            .longOpt("tls_key")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc("Path to the `--tls_certificate`'s private key.")
            .build();
    options.addOption(key);

    Option remoteHeader =
        Option.builder()
            .longOpt("token")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc("Token for open access clusters.")
            .build();
    options.addOption(remoteHeader);

    Option forwardSever =
        Option.builder()
            .longOpt("forward")
            .argName("property=value")
            .hasArgs()
            .valueSeparator()
            .numberOfArgs(2)
            .desc(
                "The service endpoint in protocol://host:port format. The protocol must be 'grpc'"
                    + " or 'grpcs' signifying plaintext or TLS-encrypted communication"
                    + " respectively.")
            .build();
    options.addOption(forwardSever);
  }
}
