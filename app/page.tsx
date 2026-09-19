"use client";

import { useEffect, useState } from "react";
import type { AgendaEvent } from "@/lib/events";

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
      setError(data.error ?? "could not create event");
      return;
    }

    setTitle("");
    setStart("");
    load();
  }

  return (
    <main>
      <h1>Agenda</h1>

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

      <ul>
        {events.map((event) => (
          <li key={event.id}>
            <strong>{event.title}</strong>
            <span>{new Date(event.start).toLocaleString("pt-BR")}</span>
          </li>
        ))}
      </ul>
    </main>
  );
}
