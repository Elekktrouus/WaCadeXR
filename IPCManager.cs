using Godot;
using System;
using System.IO;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;

public partial class IPCManager : Node
{
	private MemoryMappedFile _file;
	private MemoryMappedViewAccessor _view;
	private bool _isInitialized = false;
	private byte[] _touchData = new byte[240];

	private const string SharedMemoryName = "Local\\WACVR_SHARED_BUFFER";
	private const int SharedMemorySize = 2164;

	private const int TouchOffset = 4;
	private const int TouchCount = 240;
	private const int CabLightOffset = 240;
	private const int CabLightBytes = 4;
	private const int LightOffset = 244;
	private const int LightBytes = 1920;
	private const int LightFlagOffset = LightOffset + 3;

	public override void _Ready()
	{
		EnsureInitialization();
	}

	private void EnsureInitialization()
	{
		if (_isInitialized) return;
		InitializeIPC();
	}

	private void InitializeIPC()
	{
		try
		{
			_file = MemoryMappedFile.CreateOrOpen(
				SharedMemoryName, SharedMemorySize,
				MemoryMappedFileAccess.ReadWrite,
				MemoryMappedFileOptions.None,
				HandleInheritability.Inheritable);
			_view = _file.CreateViewAccessor();
			_isInitialized = true;
		}
		catch (Exception e)
		{
			GD.PushError($"IPC init failed: {e.Message}");
			_file = null;
			_view = null;
			_isInitialized = false;
		}
	}

	public void Reconnect()
	{
		InitializeIPC();
	}

	public byte[] GetLightData()
	{
		EnsureInitialization();
		if (!_isInitialized) return Array.Empty<byte>();
		return ReadBytesSafe(LightOffset, LightBytes);
	}

	public byte[] GetCabLightData()
	{
		EnsureInitialization();
		if (!_isInitialized) return Array.Empty<byte>();
		return ReadBytesSafe(LightOffset, CabLightBytes);
	}

	public void SetTouch(int area, bool state)
	{
		GD.Print(area + ": " + state);
		area -= 1; // 0-239
		int idx = area < 120 ? area + 120 : area - 120;
		_touchData[idx] = (byte)(state ? 1 : 0);
		SetTouchData();
	}

	private void SetTouchData()
	{
		EnsureInitialization();
		if (!_isInitialized) return;
		_view.WriteArray(TouchOffset, _touchData, 0, TouchCount);
	}

	private byte[] ReadBytesSafe(int offset, int count)
	{
		byte[] arr = new byte[count];
		_view.ReadArray(offset, arr, 0, count);
		return arr;
	}

	private void WriteByte(int offset, byte value)
	{
		if (!_isInitialized) return;
		_view.Write(offset, value);
	}

	private byte ReadByte(int offset)
	{
		if (!_isInitialized) return 0;
		_view.Read(offset, out byte value);
		return value;
	}

	public async void DisposeWait()
	{
		if (!_isInitialized) return;
		WriteByte(LightFlagOffset, 0); // clear the flag
		await ToSignal(GetTree().CreateTimer(0.1), "timeout"); // wait in case still in use
		if (!_isInitialized) return;
		byte flag = ReadByte(LightFlagOffset);
		if (flag == 0)
		{
			DisposeIPC();
		}
	}

	private void DisposeIPC()
	{
		_view?.Dispose();
		_file?.Dispose();
		_view = null;
		_file = null;
		_isInitialized = false;
		GD.Print("IPC Disposed");
	}

	public override void _ExitTree()
	{
		GD.Print("Disposing IPC");
		DisposeIPC();
	}
	
	public void SetTestButton(bool pressed) => WriteByte(0, (byte)(pressed ? 1 : 0));
	public void SetServiceButton(bool pressed) => WriteByte(1, (byte)(pressed ? 1 : 0));
	public void SetCoinButton(bool pressed) => WriteByte(2, (byte)(pressed ? 1 : 0));
	

}
