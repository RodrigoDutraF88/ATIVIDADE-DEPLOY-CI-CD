import { describe, expect, it } from "vitest";
import {
  createEvent,
  deleteEvent,
  getEvent,
  listEvents,
  updateEvent,
} from "./store";

const base = {
  title: "Reunião",
  start: "2026-03-01T10:00:00.000Z",
  end: null,
  location: null,
};

describe("store de eventos (em memória)", () => {
  it("já vem com eventos iniciais ordenados por data", async () => {
    const list = await listEvents();
    expect(list.length).toBeGreaterThanOrEqual(2);
    for (let i = 1; i < list.length; i++) {
      expect(list[i - 1].start <= list[i].start).toBe(true);
    }
  });

  it("cria, busca, atualiza e remove um evento", async () => {
    const criado = await createEvent(base);
    expect(criado.id).toBeTruthy();
    expect((await getEvent(criado.id))?.title).toBe("Reunião");

    const atualizado = await updateEvent(criado.id, {
      ...base,
      title: "Reunião nova",
    });
    expect(atualizado?.title).toBe("Reunião nova");

    expect(await deleteEvent(criado.id)).toBe(true);
    expect(await getEvent(criado.id)).toBeUndefined();
  });

  it("não atualiza nem remove id inexistente", async () => {
    expect(await updateEvent("nao-existe", base)).toBeUndefined();
    expect(await deleteEvent("nao-existe")).toBe(false);
  });
});
