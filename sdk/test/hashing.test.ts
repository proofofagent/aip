import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { Hex } from "viem";
import { computeConfigHashFromComponents, computeConfigHashes } from "../src/hashing.js";

describe("computeConfigHashes", () => {
  it("matches the known Agent Zero configuration hash", () => {
    const systemPrompt = readFileSync(resolve(process.cwd(), "../CLAUDE.md"), "utf8").replace(
      /\n+$/u,
      ""
    );
    const result = computeConfigHashes({
      systemPrompt,
      modelIdentifier: "gpt-5.3-codex",
      toolsManifest:
        "exec_command,write_stdin,list_mcp_resources,list_mcp_resource_templates,read_mcp_resource,apply_patch,update_plan,view_image,multi_tool_use.parallel,web.search_query,web.open,web.click,web.find,web.screenshot,web.image_query,web.sports,web.finance,web.weather,web.time",
      runtimeIdentifier: "codex-cli:0.101.0"
    });

    expect(result.systemPromptHash).toBe(
      "0xbe505a58dbb1c83c908330e6ad8e83f910a5eac4dea4d76605ccc1ff182e12e7"
    );
    expect(result.modelHash).toBe(
      "0x94ee34552bbdf6d781e5603c0b4737a2429421e67e180f02fd58c73c012c304c"
    );
    expect(result.toolsHash).toBe(
      "0x2abadedc4530197e67253698a3be086cda391546a87465af3fd238310154e2dd"
    );
    expect(result.runtimeHash).toBe(
      "0xeb935f2db1713823a7e5c986822a1350b5a6f76f35cfd3e488f60fc479b1cc6f"
    );
    expect(result.configHash).toBe(
      "0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f"
    );
  });

  it("computes from component hashes", () => {
    const configHash = computeConfigHashFromComponents({
      systemPromptHash:
        "0xbe505a58dbb1c83c908330e6ad8e83f910a5eac4dea4d76605ccc1ff182e12e7" as Hex,
      modelHash: "0x94ee34552bbdf6d781e5603c0b4737a2429421e67e180f02fd58c73c012c304c" as Hex,
      toolsHash: "0x2abadedc4530197e67253698a3be086cda391546a87465af3fd238310154e2dd" as Hex,
      runtimeHash: "0xeb935f2db1713823a7e5c986822a1350b5a6f76f35cfd3e488f60fc479b1cc6f" as Hex
    });

    expect(configHash).toBe("0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f");
  });

  it("rejects non-bytes32 component hashes", () => {
    expect(() =>
      computeConfigHashFromComponents({
        systemPromptHash: "0x1234",
        modelHash:
          "0x94ee34552bbdf6d781e5603c0b4737a2429421e67e180f02fd58c73c012c304c" as Hex,
        toolsHash:
          "0x2abadedc4530197e67253698a3be086cda391546a87465af3fd238310154e2dd" as Hex,
        runtimeHash:
          "0xeb935f2db1713823a7e5c986822a1350b5a6f76f35cfd3e488f60fc479b1cc6f" as Hex
      })
    ).toThrow(/bytes32/);
  });
});
