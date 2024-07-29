package contracts

import (
	"bytes"
	"embed"
	"text/template"
)

//go:embed *.cdc
var Cdc embed.FS

// Tmpl ready to be used for execute
var Tmpl *template.Template

func init() {
	Tmpl, _ = template.ParseFS(Cdc, "*.cdc")
}

// helper struct to include variables used in cdc template
type Val struct {
	FungibleTokenAddr, BridgeAddr, PbAddr, PbPeggedAddr, DelayedTransferAddr, VolumeControlAddr string
	// to deploy different PegToken.cdc contracts, eg. WETH, USDT, replace in PegToken.cdc
	TokenName string
	// FTMinterBurner, needed by PegBridge and PegToken
	FTMBAddr string
}

// name is cdc file name like get_balance.cdc, data is struct with fields for template variable
// return replaced string
func RunTmpl(name string, data interface{}) (string, error) {
	var b bytes.Buffer
	err := Tmpl.Lookup(name).Execute(&b, data)
	if err != nil {
		return "", err
	}
	return b.String(), nil
}
