package main

import (
	"fmt"
	"strconv"
	"bytes"
	"vdcs"
	"log"
	"os"
	"time"
)


func main() {
	vdcs.ReadyMutex.Lock()
	vdcs.ReadyFlag = false
	vdcs.ReadyMutex.Unlock()
	port, err := strconv.ParseInt(os.Args[1], 10, 32)
	if err != nil {log.Fatal("Error reading commandline arguments", err)}
	vdcs.SetDirectoryInfo([]byte("127.0.0.1"), int(port))
	vdcs.ClientRegister()
	go vdcs.ClientHTTP()
