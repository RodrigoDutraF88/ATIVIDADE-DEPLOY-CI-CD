import { describe, expect, it } from "vitest";
import { parseEventInput } from "./events";

describe("parseEventInput", () => {
  it("aceita um evento válido", () => {
    const r = parseEventInput({
      title: "Mentoria",
      start: "2026-02-10T14:00:00.000Z",
    });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.title).toBe("Mentoria");
      expect(r.value.end).toBeNull();
      expect(r.value.location).toBeNull();
    }
  });

  it("recusa título vazio", () => {
    const r = parseEventInput({ title: "  ", start: "2026-02-10T14:00:00.000Z" });
    expect(r).toEqual({ ok: false, error: "title is required" });
  });

  it("recusa data de início inválida", () => {
    const r = parseEventInput({ title: "X", start: "não é data" });
    expect(r.ok).toBe(false);
  });

  it("recusa fim antes do início", () => {
    const r = parseEventInput({
      title: "X",
      start: "2026-02-10T14:00:00.000Z",
      end: "2026-02-10T13:00:00.000Z",
    });
    expect(r).toEqual({ ok: false, error: "end must not be before start" });
  });

  it("recusa corpo que não é objeto", () => {
    expect(parseEventInput("oi").ok).toBe(false);
    expect(parseEventInput(null).ok).toBe(false);
  });

  it("apara o título e trata location vazia como nula", () => {
    const r = parseEventInput({
      title: "  Café  ",
      start: "2026-02-10T14:00:00.000Z",
      location: "   ",
    });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.title).toBe("Café");
      expect(r.value.location).toBeNull();
    }
  });
});
