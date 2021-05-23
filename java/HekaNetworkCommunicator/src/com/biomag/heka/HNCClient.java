/* HNCClient.java
 * 
 * Copyright
 * Krisztián Koós
 * koos.krisztian@brc.mta.hu
 * BIOMAG group
 * Mar 16, 2017
 *
 */ 
package com.biomag.heka;

import java.io.*;
import java.net.*;

public class HNCClient {
	
	private String hostName;
	private int port;
	private Socket socket;
	private BufferedReader in;
	private PrintWriter out;
	private boolean closed = false;
	
	public HNCClient(String hostName) throws Exception {
		this(hostName, HNCServer.defaultPort);
	}
	
	public HNCClient(String hostName, int port) throws Exception {
		this.hostName = hostName;
		this.port = port;
		init();
	}
	
	public void close() {
		if (closed) {
			return;
		}
		try {
			in.close();
		} catch (IOException e) {
			System.err.println("Could not close the input stream.");
			e.printStackTrace();
		}
		out.close();
		try {
			socket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		closed = true;
	}
	
	public void sendMessage(String message) throws Exception {
		if (closed) {
			throw new Exception("Cannot send message, because streams are already closed!");
		}
		out.println(message);
	}
	
	public void finalize() {
		close();
	}
	
	private void init() throws Exception{
		try {
			socket = new Socket(hostName, port);
			out = new PrintWriter(socket.getOutputStream(), true);
            in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
		} catch (UnknownHostException e) {
			String message = "Don't know about host " + hostName;
            System.err.println(message);
            throw new Exception(message, e);
        } catch (IOException e) {
        	String message = "Couldn't get I/O for the connection to " + hostName;
            System.err.println(message);
            throw new Exception(message, e);
        }
	}
	
	public static void main(String[] args) throws Exception {
		if (args.length < 1 || args.length > 2) {
			System.err.println("Usage: java com.biomag.heka.HNCClient <host> [<port>]");
			System.exit(1);
		}
		HNCClient client = null;
		if (args.length == 1) {
			client = new HNCClient(args[0]);
		} else {
			int port = Integer.parseInt(args[1]);
			client = new HNCClient(args[0], port);
		}
		
		client.sendMessage("Client sends his regards!\nHope PatchMaster will eat text.");
		client.close();
	}
}