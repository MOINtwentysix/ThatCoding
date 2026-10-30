import { Keymap } from "../context/keymap"
import { useTheme } from "../context/theme"
import { DialogHeader, DialogLayout, useDialog } from "../ui/dialog"
import { openUrl } from "@opencode/util/open"
import { Link } from "../ui/link"
import { TextAttributes } from "@opentui/core"
import { useExit } from "../context/exit"

export const TERMS_URL = "https://moin26.dev/rechtliches/nutzungsbedingungen/thatcode/"
export const PRIVACY_URL = "https://moin26.dev/rechtliches/datenschutz/thatcode/"

export function DialogTerms(props: { onAccept: () => void }) {
  const dialog = useDialog()
  const exit = useExit()
  const theme = useTheme().surface("dialog")

  const accept = () => {
    props.onAccept()
    dialog.clear()
  }

  const decline = () => {
    dialog.clear()
    exit("Nutzungsbedingungen nicht akzeptiert")
  }

  Keymap.createLayer(() => ({
    mode: "modal",
    commands: [
      {
        bind: "return",
        title: "Zustimmen",
        group: "Dialog",
        run: accept,
      },
      {
        bind: "escape",
        title: "Ablehnen & Beenden",
        group: "Dialog",
        run: decline,
      },
      {
        bind: "1",
        title: "Nutzungsbedingungen im Browser öffnen",
        group: "Dialog",
        run: () => void openUrl(TERMS_URL).catch(() => {}),
      },
      {
        bind: "2",
        title: "Datenschutz im Browser öffnen",
        group: "Dialog",
        run: () => void openUrl(PRIVACY_URL).catch(() => {}),
      },
    ],
  }))

  return (
    <DialogLayout
      header={<DialogHeader title="Nutzungs- & Datenschutzbedingungen" />}
      footer={{
        actions: {
          primary: [
            { title: "ablehnen (esc)", key: "esc", onTrigger: decline },
            { title: "zustimmen (enter)", key: "enter", onTrigger: accept },
          ],
        },
      }}
      legacyFooter={
        <box flexDirection="row" justifyContent="flex-end" gap={1}>
          <box
            paddingLeft={2}
            paddingRight={2}
            backgroundColor={theme.background.action.secondary.base}
            onMouseUp={decline}
          >
            <text fg={theme.text.muted}>Ablehnen (Esc)</text>
          </box>
          <box
            paddingLeft={2}
            paddingRight={2}
            backgroundColor={theme.background.action.primary.focused}
            onMouseUp={accept}
          >
            <text fg={theme.text.action.primary.focused}>Zustimmen (Enter)</text>
          </box>
        </box>
      }
    >
      <box flexDirection="column" gap={1}>
        <text fg={theme.text.base} attributes={TextAttributes.BOLD}>
          Willkommen bei ThatCoding!
        </text>
        <text fg={theme.text.muted} wrapMode="word">
          Bevor du ThatCoding nutzen kannst, musst du bitte den Nutzungsbedingungen und der Datenschutzerklärung zustimmen.
        </text>
        <box flexDirection="column" gap={1} paddingTop={1} paddingBottom={1}>
          <box flexDirection="row" gap={1}>
            <text fg={theme.hue.accent[200] ?? theme.text.base} attributes={TextAttributes.BOLD}>
              [1]
            </text>
            <text fg={theme.text.base}>Nutzungsbedingungen:</text>
            <Link href={TERMS_URL} fg={theme.hue.accent[200] ?? theme.text.base}>
              {TERMS_URL}
            </Link>
          </box>
          <box flexDirection="row" gap={1}>
            <text fg={theme.hue.accent[200] ?? theme.text.base} attributes={TextAttributes.BOLD}>
              [2]
            </text>
            <text fg={theme.text.base}>Datenschutzerklärung:</text>
            <Link href={PRIVACY_URL} fg={theme.hue.accent[200] ?? theme.text.base}>
              {PRIVACY_URL}
            </Link>
          </box>
        </box>
        <text fg={theme.text.muted}>
          Drücke [1] oder [2], um die Links direkt im Browser zu öffnen.
        </text>
        <text fg={theme.text.muted}>
          Mit Enter stimmst du zu, mit Esc beendest du die Anwendung.
        </text>
      </box>
    </DialogLayout>
  )
}
