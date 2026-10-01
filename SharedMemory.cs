using Godot;
using System;
using System.IO;
using System.IO.MemoryMappedFiles;

public partial class SharedMemory : RefCounted
{
	private MemoryMappedFile _file;
	private MemoryMappedViewAccessor _view;

	public bool Open(string name, int size)
	{
		try
		{
			_file = MemoryMappedFile.CreateOrOpen(
				name, size,
				MemoryMappedFileAccess.ReadWrite,
				MemoryMappedFileOptions.None,
				HandleInheritability.Inheritable);
			_view = _file.CreateViewAccessor();
			return true;
		}
		catch (Exception e)
		{
			GD.PushError($"SharedMemory.Open failed: {e.Message}");
			Close();
			return false;
		}
	}

	public byte[] ReadBytes(int offset, int count)
	{
		var arr = new byte[count];
		if (_view != null)
			_view.ReadArray(offset, arr, 0, count);
		return arr;
	}

	public void WriteBytes(int offset, byte[] data)
	{
		if (_view != null)
			_view.WriteArray(offset, data, 0, data.Length);
	}

	public void WriteByte(int offset, int value)
	{
		if (_view != null)
			_view.Write(offset, (byte)value);
	}
	
	

	public void Close()
	{
		_view?.Dispose();
		_file?.Dispose();
		_view = null;
		_file = null;
	}
}
