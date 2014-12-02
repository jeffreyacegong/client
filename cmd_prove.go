package main

import (
	"fmt"
	"github.com/codegangsta/cli"
	"github.com/keybase/go-libkb"
)

type CmdProve struct {
	me                *libkb.User
	force             bool
	service, username string
	output            string
	st                libkb.ServiceType
}

func (v *CmdProve) ParseArgv(ctx *cli.Context) error {
	nargs := len(ctx.Args())
	var err error
	v.force = ctx.Bool("force")
	v.output = ctx.String("output")

	if nargs > 2 || nargs == 0 {
		err = fmt.Errorf("prove takes 1 or args: <service> [<username>]")
	} else {
		v.service = ctx.Args()[0]
		if nargs == 2 {
			v.username = ctx.Args()[1]
		}
		if v.st = libkb.GetServiceType(v.service); v.st == nil {
			err = BadServiceError{v.service}
		}
	}
	return err
}

func (v *CmdProve) Login() (err error) {
	return G.LoginState.Login(libkb.LoginArg{})
}
func (v *CmdProve) LoadMe() (err error) {
	v.me, err = libkb.LoadMe(libkb.LoadUserArg{LoadSecrets: true, AllKeys: false})
	return
}
func (v *CmdProve) CheckExists1() (err error) {
	proofs := v.me.IdTable.GetActiveProofsFor(v.st)
	if len(proofs) != 0 {
		lst := proofs[len(proofs)-1]
		prompt := "You already have a proof " +
			ColorString("bold", lst.ToDisplayString()) + "; overwrite?"
		def := false
		var redo bool
		redo, err = G_UI.PromptYesNo(prompt, &def)
		if !redo {
			err = NotConfirmedError{}
		}
	}
	return
}

func (v *CmdProve) PromptRemoteName() (err error) {
	if len(v.username) == 0 {

	}
	return
}
func (v *CmdProve) NormalizeRemoteName() (err error) {
	return
}
func (v *CmdProve) CheckExists2() (err error) {
	return
}
func (v *CmdProve) DoPrechecks() (err error) {
	return
}
func (v *CmdProve) DoWarnings() (err error) {
	return
}
func (v *CmdProve) GenerateProof() (err error) {
	return
}
func (v *CmdProve) PostProofToServer() (err error) {
	return
}
func (v *CmdProve) PromptPostedLoop() (err error) {
	return
}

func (v *CmdProve) Run() (err error) {

	if err = v.Login(); err != nil {
		return
	}
	if err = v.LoadMe(); err != nil {
		return
	}
	if err = v.CheckExists1(); err != nil {
		return
	}
	if err = v.PromptRemoteName(); err != nil {
		return
	}
	if err = v.NormalizeRemoteName(); err != nil {
		return
	}
	if err = v.CheckExists2(); err != nil {
		return
	}
	if err = v.DoPrechecks(); err != nil {
		return
	}
	if err = v.DoWarnings(); err != nil {
		return
	}
	if err = v.GenerateProof(); err != nil {
		return
	}
	if err = v.PostProofToServer(); err != nil {
		return
	}
	if err = v.PromptPostedLoop(); err != nil {
		return
	}
	return nil
}

func NewCmdProve(cl *CommandLine) cli.Command {
	return cli.Command{
		Name:        "prove",
		Usage:       "keybase prove <service> [<username>]",
		Description: "generate a new proof",
		Flags: []cli.Flag{
			cli.StringFlag{
				Name:  "output, o",
				Usage: "output proof text to a file (rather than standard out)",
			},
			cli.BoolFlag{
				Name:  "force, f",
				Usage: "don't stop for any prompts",
			},
		},
		Action: func(c *cli.Context) {
			cl.ChooseCommand(&CmdProve{}, "prove", c)
		},
	}
}

func (v *CmdProve) GetUsage() libkb.Usage {
	return libkb.Usage{
		Config:    true,
		API:       true,
		Terminal:  true,
		KbKeyring: true,
	}
}
