"use client";

import { useEffect, useState } from "react";
import type { AgendaEvent } from "@/lib/events";

const formatador = new Intl.DateTimeFormat("pt-BR", {
  day: "2-digit",
  month: "short",
  hour: "2-digit",
  minute: "2-digit",
});

export default function Home() {
  const [events, setEvents] = useState<AgendaEvent[]>([]);
  const [title, setTitle] = useState("");
  const [start, setStart] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    const res = await fetch("/api/events");
    setEvents(await res.json());
  }

  useEffect(() => {
    load();
  }, []);

  async function addEvent(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const res = await fetch("/api/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, start }),
    });

    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "não foi possível criar o evento");
      return;
    }

    setTitle("");
    setStart("");
    load();
  }

  return (
    <main>
      <div className="cartao">
        <header>
          <h1>Agenda</h1>
          <p>Seus compromissos, num lugar só.</p>
        </header>

        <form onSubmit={addEvent}>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Título do compromisso"
          />
          <input
            type="datetime-local"
            value={start}
            onChange={(e) => setStart(e.target.value)}
          />
          <button type="submit">Adicionar</button>
        </form>

        {error && <p className="error">{error}</p>}

        {events.length === 0 ? (
          <p className="vazio">Nenhum compromisso ainda.</p>
        ) : (
          <ul>
            {events.map((event) => (
              <li key={event.id}>
                <div>
                  <div className="titulo">{event.title}</div>
                  {event.location && <div className="local">{event.location}</div>}
                </div>
                <span className="quando">
                  {formatador.format(new Date(event.start))}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </main>
  );
}
