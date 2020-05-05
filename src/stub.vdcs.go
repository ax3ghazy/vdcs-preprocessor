package main

import (
	"bytes"
	"fmt"
	"os"
	"strconv"
	"time"

	"./vdcs"
)

func main() {
	vdcs.ReadyMutex.Lock()
	vdcs.ReadyFlag = false
	vdcs.ReadyMutex.Unlock()

	username := os.Args[1]
	cleosKey := os.Args[2]
	actionAccount := os.Args[3]
	passwordWallet := os.Args[4]

	vdcs.SetDecentralizedDirectoryInfo("http://127.0.0.1:8888", actionAccount, passwordWallet)
	vdcs.ClientRegisterDecentralized(username, cleosKey)

	go vdcs.ClientHTTP()
