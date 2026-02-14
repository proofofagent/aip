import { describe, expect, it } from "vitest";
import { createPublicClient, encodeFunctionData, http, type Address, type Hex } from "viem";
import { AgentRegistryClient } from "../src/client.js";
import { agentRegistryAbi } from "../src/abi.js";

describe("AgentRegistryClient calldata builders", () => {
  const registryAddress = "0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97" as Address;
  const publicClient = createPublicClient({
    transport: http("https://sepolia.base.org")
  });
  const client = new AgentRegistryClient({
    registryAddress,
    publicClient
  });

  it("builds register calldata", () => {
    const configHash =
      "0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f" as Hex;
    const metadataURI = "ipfs://placeholder-aip-agent-zero-v0.1";

    const calldata = client.buildRegisterCalldata({
      configHash,
      metadataURI
    });

    const expected = encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "register",
      args: [configHash, metadataURI]
    });

    expect(calldata).toBe(expected);
  });

  it("builds updateConfig transaction", () => {
    const agentKey = "0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072" as Address;
    const newConfigHash =
      "0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f" as Hex;
    const metadataURI = "ipfs://placeholder-aip-agent-zero-v0.1";

    const tx = client.buildUpdateConfigTransaction({
      agentKey,
      newConfigHash,
      metadataURI
    });

    const expectedData = encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "updateConfig",
      args: [agentKey, newConfigHash, metadataURI]
    });

    expect(tx.to).toBe(registryAddress);
    expect(tx.data).toBe(expectedData);
  });
});
