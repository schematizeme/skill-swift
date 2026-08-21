# Anexo volátil — versões e ferramental (Swift / Apple)

> Parte da skill **schematize-swift**. **Fonte volátil:** tudo aqui tem prazo de validade e é
> atualizado à parte do corpo normativo, que não crava número (regra `anexo-volatil` do lint).
>
> **Verificado em: 2026-08-21.** Cadência: trimestral e antes de cada release da skill.
> **Ressalva honesta:** esta é a única skill do catálogo cuja toolchain **não roda na máquina de
> referência** (Linux). Os números abaixo vêm da documentação oficial, não de execução local — e é
> por isso que eles moram aqui, no anexo datado, e não no corpo.

## Linguagem e toolchain

- **Piso normativo:** rodar numa versão **em suporte**, com a toolchain **fixada** no repo.
- **Swift 6 mode / strict concurrency**: é o divisor de águas do idioma — ele transforma data race
  em **erro de compilação**. A casa exige o modo estrito em código novo; migração de legado é
  incremental (por módulo), com ADR quando o prazo for longo.
- **`swift-tools-version`** declarado no `Package.swift`; **versão de Xcode** fixada no CI.

## Ferramental

| Ferramenta | Papel | Nota |
|---|---|---|
| **SwiftPM** | dependência e build | `Package.resolved` **commitado** — é o lockfile |
| **`swift-format`** ou **SwiftLint** | formatação e lint | um só, escolhido e travando o CI |
| **`swift-testing`** | testes (`@Test`, `#expect`) | XCTest onde já existe |
| **Instruments / Leaks** | ciclo de retenção e memória | nos fluxos críticos, antes do release |
| **Thread Sanitizer** | data race no que ainda não está em Swift 6 mode | no CI, nos testes de integração |

## Regra que NÃO é volátil

Force-unwrap em produção, segredo no bundle e `catch {}` vazio são VETADOS **em qualquer versão**.
O número muda; o piso não.
