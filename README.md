# ChahgArtix
 Обмен с Artix

V 1.0  - Обработка загрузки данных из Артикс, реализована загрузка и закрытие кассовых смен.


sequenceDiagram %% tab completion: 'diagram'
  %% tab completion: 'participant'
  participant A as Alice
  participant B as Bob
  participant C as Carol
  %% tab completion: 'note'
  Note left of A: Alice likes to chat
  %% tab completion: 'msg'
  A->B: Hello Bob, how are you?
  loop Healthcheck
    B->B: Bob checks himself...
  end %% tab completion: 'loop'
  Note over B: Bob whispers when sick
  alt is sick
    B-->A: Not so good :(
  else is well
    B->A: Feeling fresh like a daisy
  end %% tab completion: 'alt'
  opt Extra response
    B->A: You, Alice?
  end %% tab completion: 'opt'
  Note right of C: Carol is the boss
  C->>A: Get back to work!
  loop Every hour
    A->>B: Request 1
    %% tab completion: 'activate'
    activate B
    A-x+B: Request 2
    B--x-A: Response 2
    B-->>A: Response 1
    deactivate B
  end
