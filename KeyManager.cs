using Godot;
using System;
using System.Runtime.InteropServices;

public partial class KeyManager : Node
{
	[DllImport("user32.dll")]
	private static extern uint MapVirtualKey(uint uCode, uint uMapType);

	[DllImport("user32.dll")]
	private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

	private const uint KEYEVENTF_KEYDOWN = 0x0000;
	private const uint KEYEVENTF_KEYUP = 0x0002;

	public static void PressKey(byte vkCode)
	{
		byte scanCode = (byte)MapVirtualKey(vkCode, 0);
		keybd_event(vkCode, scanCode, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
	}

	public static void ReleaseKey(byte vkCode)
	{
		byte scanCode = (byte)MapVirtualKey(vkCode, 0);
		keybd_event(vkCode, scanCode, KEYEVENTF_KEYUP, UIntPtr.Zero);
	}

	public static void TapKey(byte vkCode)
	{
		PressKey(vkCode);
		ReleaseKey(vkCode);
	}
}
