package kha.graphics4;

import js.html.webgl.GL;
import kha.arrays.Float32Array;
import kha.arrays.Int16Array;
import kha.graphics4.Usage;
import kha.graphics4.VertexStructure;

class VertexBuffer {
	private var buffer: Dynamic;
	public var _data: Float32Array;
	private var mySize: Int;
	private var myStride: Int;
	private var sizes: Array<Int>;
	private var offsets: Array<Int>;
	private var types: Array<Int>;
	private var usage: Usage;
	private var instanceDataStepRate: Int;
	private var lockStart: Int = 0;
	private var lockEnd: Int = 0;
	
	public function new(vertexCount: Int, structure: VertexStructure, usage: Usage, instanceDataStepRate: Int = 0, canRead: Bool = false) {
		this.usage = usage;
		this.instanceDataStepRate = instanceDataStepRate;
		mySize = vertexCount;
		myStride = 0;
		for (element in structure.elements) {
			switch (element.data) {
			case Float1:
				myStride += 4 * 1;
			case Float2:
				myStride += 4 * 2;
			case Float3:
				myStride += 4 * 3;
			case Float4:
				myStride += 4 * 4;
			case Float4x4:
				myStride += 4 * 4 * 4;
			case Short2Norm:
				myStride += 2 * 2;
			case Short4Norm:
				myStride += 2 * 4;
			}
		}
	
		buffer = SystemImpl.gl.createBuffer();
		_data = new Float32Array(Std.int(vertexCount * myStride / 4));
		
		sizes = new Array<Int>();
		offsets = new Array<Int>();
		types = new Array<Int>();
		sizes[structure.elements.length - 1] = 0;
		offsets[structure.elements.length - 1] = 0;
		types[structure.elements.length - 1] = 0;
		
		var offset = 0;
		var index = 0;
		for (element in structure.elements) {
			var size;
			var type;
			switch (element.data) {
			case Float1:
				size = 1;
				type = GL.FLOAT;
			case Float2:
				size = 2;
				type = GL.FLOAT;
			case Float3:
				size = 3;
				type = GL.FLOAT;
			case Float4:
				size = 4;
				type = GL.FLOAT;
			case Float4x4:
				size = 4 * 4;
				type = GL.FLOAT;
			case Short2Norm:
				size = 2;
				type = GL.SHORT;
			case Short4Norm:
				size = 4;
				type = GL.SHORT;
			}
			sizes[index] = size;
			offsets[index] = offset;
			types[index] = type;
			switch (element.data) {
			case Float1:
				offset += 4 * 1;
			case Float2:
				offset += 4 * 2;
			case Float3:
				offset += 4 * 3;
			case Float4:
				offset += 4 * 4;
			case Float4x4:
				offset += 4 * 4 * 4;
			case Short2Norm:
				offset += 2 * 2;
			case Short4Norm:
				offset += 2 * 4;
			}
			++index;
		}
	}

	public function delete(): Void {
		_data = null;
		SystemImpl.gl.deleteBuffer(buffer);
	}
	
	public function lock(?start: Int, ?count: Int): Float32Array {
		lockStart = start != null ? start : 0; 
		lockEnd = count != null ? start + count : mySize; 
		return _data.subarray(lockStart * stride(), lockEnd * stride());
	}

	public function lockInt16(?start: Int, ?count: Int): Int16Array {
		return new Int16Array(untyped lock(start, count).buffer);
	}
	
	public function unlock(?count: Int): Void {
		if(count != null) lockEnd = lockStart + count;
		SystemImpl.gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
		SystemImpl.gl.bufferData(GL.ARRAY_BUFFER, _data.subarray(lockStart * stride(), lockEnd * stride()).data(), usage == Usage.DynamicUsage ? GL.DYNAMIC_DRAW : GL.STATIC_DRAW);
	}
	
	public function stride(): Int {
		return myStride;
	}
	
	public function count(): Int {
		return mySize;
	}
	
	public function set(offset: Int): Int {
		var ext: Dynamic = SystemImpl.gl2 ? true : SystemImpl.gl.getExtension("ANGLE_instanced_arrays");
		SystemImpl.gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
		var attributesOffset = 0;
		for (i in 0...sizes.length) {
			if (sizes[i] > 4) {
				var size = sizes[i];
				var addonOffset = 0;
				while (size > 0) {
					SystemImpl.gl.enableVertexAttribArray(offset + attributesOffset);
					SystemImpl.gl.vertexAttribPointer(offset + attributesOffset, 4, GL.FLOAT, false, myStride, offsets[i] + addonOffset);
					if (ext) {
						if (SystemImpl.gl2) {
							untyped SystemImpl.gl.vertexAttribDivisor(offset + attributesOffset, instanceDataStepRate);
						}
						else {
							ext.vertexAttribDivisorANGLE(offset + attributesOffset, instanceDataStepRate);
						}
					}
					size -= 4;
					addonOffset += 4 * 4;
					++attributesOffset;
				}
			}
			else {
				var normalized = types[i] == GL.FLOAT ? false : true;
				SystemImpl.gl.enableVertexAttribArray(offset + attributesOffset);
				SystemImpl.gl.vertexAttribPointer(offset + attributesOffset, sizes[i], types[i], normalized, myStride, offsets[i]);
				if (ext) {
					if (SystemImpl.gl2) {
						untyped SystemImpl.gl.vertexAttribDivisor(offset + attributesOffset, instanceDataStepRate);
					}
					else {
						ext.vertexAttribDivisorANGLE(offset + attributesOffset, instanceDataStepRate);
					}
				}
				++attributesOffset;
			}
		}
		return attributesOffset;
	}
}
