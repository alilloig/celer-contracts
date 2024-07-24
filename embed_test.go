package contracts

import (
	"testing"
)

func TestRunTmpl(t *testing.T) {
	for _, tm := range Tmpl.Templates() {
		t.Error(tm.Name())
	}
	res, _ := RunTmpl("cBridge.cdc", &Val{
		PbAddr: "0x1238901820312",
	})
	t.Error(res)
}
