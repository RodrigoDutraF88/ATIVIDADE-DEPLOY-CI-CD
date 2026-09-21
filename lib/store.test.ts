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

describe("store de eventos", () => {
  it("já vem com eventos iniciais ordenados por data", () => {
    const list = listEvents();
    expect(list.length).toBeGreaterThanOrEqual(2);
    for (let i = 1; i < list.length; i++) {
      expect(list[i - 1].start <= list[i].start).toBe(true);
    }
  });

  it("cria, busca, atualiza e remove um evento", () => {
    const criado = createEvent(base);
    expect(criado.id).toBeTruthy();
    expect(getEvent(criado.id)?.title).toBe("Reunião");

    const atualizado = updateEvent(criado.id, { ...base, title: "Reunião nova" });
    expect(atualizado?.title).toBe("Reunião nova");

    expect(deleteEvent(criado.id)).toBe(true);
    expect(getEvent(criado.id)).toBeUndefined();
  });

  it("não atualiza nem remove id inexistente", () => {
    expect(updateEvent("nao-existe", base)).toBeUndefined();
    expect(deleteEvent("nao-existe")).toBe(false);
  });
});
