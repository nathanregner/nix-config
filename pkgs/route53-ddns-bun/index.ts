import { Command, Option } from "@commander-js/extra-typings";
import * as os from "os";
import * as ip from "ip";
import { Route53Client, ListResourceRecordSetsCommand, UpdateResourceRecordSetsCommand } from "@aws-sdk/client-route-53";

const networkInterfaces = os.networkInterfaces();
console.log(networkInterfaces);

console.log(ip.address());

function int(arg: string, _previous: number) {
  return parseInt(arg);
}

const program = new Command()
  .requiredOption("--hosted-zone-id <zone-id>")
  .requiredOption("--domain <domain>")
  .addOption(
    new Option("--ip <type>")
      .makeOptionMandatory()
      .choices(["local", "public"] as const),
  )
  .option("--ttl <ttl>", "TTL in seconds", int)
  .parse();

const opts = program.opts();
console.log("Hello via Bun!");
console.log(opts);

async function getIp(type: "local" | "public") {
  if (type === "local") {
    return ip.address();
  } else {
    const response = await fetch("https://checkip.amazonaws.com/");
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return response.text();
  }
}

const client = new Route53Client();
const response = await client.send(new ListResourceRecordSetsCommand({
HostedZoneId:opts.hostedZoneId}));
console.log(response);


 // console.log(await getIp(opts.ip));
