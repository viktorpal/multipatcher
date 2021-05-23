/* HNCServer.java
 * 
 * Copyright
 * Krisztián Koós
 * koos.krisztian@brc.mta.hu
 * BIOMAG group
 * Mar 16, 2017
 *
 */ 
package com.biomag.heka;

import java.net.*;
import java.util.Scanner;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeoutException;
import java.io.*;

public class HNCServer extends Thread {

	public static final int defaultPort = 3394;
	public static final String commandFilename = "E9Batch.In";
	public static final String responseFilename = "E9Batch.Out";
	public static final int maxFilecheckAttempts = 50;
	public static final String secretMessageToCloseServer = "Ignore this. Call me an idiot later."; // I'm sorry.
	
	private int port;
	private String commandFilepath;
	private String responseFilepath;
	private boolean listening = true;
	private LinkedBlockingQueue<String> commandQueue = new LinkedBlockingQueue<String>();
	private HNCServerWorker worker;
	
	public HNCServer(String batchControlFolder) {
		this(batchControlFolder, defaultPort);
	}
	
	public HNCServer(String batchControlFolder, int port) {
		this.commandFilepath = new File(batchControlFolder, commandFilename).getAbsolutePath();
		this.responseFilepath = new File(batchControlFolder, responseFilename).getAbsolutePath();
		this.port = port;
		init();
	}
	
	public int getPort() {
		return port;
	}
	
	public boolean isListening() {
		return listening;
	}

	public void setListening(boolean listening) {
		this.listening = listening;
	}
	
	public void init() {
		System.out.println("Checking communication files...");
		try {
			checkOrCreateCommandFile();
		} catch (IOException e) {
			System.err.println("Could not write to file!");
			System.exit(-1);
		} catch (TimeoutException e) {
			System.err.println(e.getMessage());
			System.exit(-1);
		}
		System.out.println("Starting worker thread...");
		this.worker = new HNCServerWorker(commandQueue, commandFilepath, responseFilepath);
		this.worker.start();
	}
	
	public void run() {
		
		try (ServerSocket serverSocket = new ServerSocket(port)) { 
            while (listening) {
            	Socket socket = serverSocket.accept();
            	
            	//Could start a thread here and have an EndOfMessage, and every line would be a different command
//	            new HNCServerThread(serverSocket.accept(), commandFilepath, responseFilepath).start();
//	            System.out.println("Client connected.");
            	try {
            		BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            		String inputLine = in.readLine();
            		if (HNCServer.secretMessageToCloseServer.equals(inputLine)) {
            			listening = false;
            		} else {
            			this.commandQueue.put(inputLine);
            		}
    				socket.close();
    			} catch (IOException | InterruptedException e) {
    				System.err.println(e.getMessage());
    			}
	        }
	    } catch (IOException e) {
            System.err.println("Could not listen on port " + port);
            System.exit(-1);
        }
		worker.interrupt();
	}
	
	private void checkOrCreateCommandFile() throws IOException, TimeoutException {
		if (! (new File(responseFilepath).exists())) { // if no response file exists, create a dummy command
        	RandomAccessFile commandRaf = new RandomAccessFile(commandFilepath, "rw");
        	commandRaf.writeBytes("-112" + System.lineSeparator());
        	commandRaf.setLength(commandRaf.getFilePointer());
        	commandRaf.seek(0);
        	commandRaf.writeBytes("+");
        	commandRaf.close();
        }
		int counter = 0;
        while (! (new File(responseFilepath).exists())) { // wait for PatchMaster to answer
        	if (counter > HNCServer.maxFilecheckAttempts) {
        		throw new TimeoutException("No \"response\" file found. Check if PatchMaster is running and is in receiver mode!");
        	}else {
        		counter += 1;
        	}
        	try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				System.err.println("Interrupted while waiting for command file.");
				e.printStackTrace();
				break;
			}
        }
	}
	
	public static void main(String[] args) throws IOException {
		String batchControlFolder;
		HNCServer server = null;
		if (args.length < 1 || args.length > 2) {
			System.err.println("Usage: java com.biomag.heka.HNCServer <batchControlFolder> [<port>]");
			System.exit(1);
		}
		batchControlFolder = args[0];
		if (args.length == 2) {
			int port = Integer.parseInt(args[1]);
			server = new HNCServer(batchControlFolder, port);
		} else {
			server = new HNCServer(batchControlFolder);
		}
		server.start();
		System.out.println("Server started.");
		
//		try {
//			HNCClient clientTest = new HNCClient("localhost");
//			clientTest.sendMessage("do this");
//			clientTest.close();
//			clientTest = new HNCClient("localhost");
//			clientTest.sendMessage("do that");
//			clientTest.close();
//		} catch (Exception e1) {
//			e1.printStackTrace();
//		}
		
		boolean waitingCommands = true;
		Scanner scanner = new Scanner(System.in);
		while (waitingCommands) {
        	String line = scanner.nextLine();
        	line = line.toLowerCase();
        	if ("q".equals(line) || "quit".equals(line) || "bye".equals(line) || "exit".equals(line)) {
        		waitingCommands = false;
        		System.out.println("Exiting...");
        		
        		try {
					HNCClient client = new HNCClient("localhost");
					server.interrupt();
					client.sendMessage(HNCServer.secretMessageToCloseServer);
					client.close();
				} catch (Exception e) {
					System.err.println("Could not send the shutdown signal to the server. You might have to force-close it.");
				}
        	} else {
        		System.out.println("Help: you can shut down the server by typing 'q'. Currently no other commands are supported.");
        	}
        }
		scanner.close();
	}
}