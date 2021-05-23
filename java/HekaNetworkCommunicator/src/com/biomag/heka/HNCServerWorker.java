/* HNCServerThread.java
 * 
 * Copyright
 * Krisztián Koós
 * koos.krisztian@brc.mta.hu
 * BIOMAG group
 * Mar 16, 2017
 *
 */ 
package com.biomag.heka;

import java.util.concurrent.LinkedBlockingQueue;
import java.io.*;

public class HNCServerWorker extends Thread {
	private static final int MAX_ATTEMPTS = 1000;
	
    private LinkedBlockingQueue<String> commandQueue;
    private String commandFilepath;
    private String responseFilepath;
    private boolean running = true;

    public HNCServerWorker(LinkedBlockingQueue<String> commandQueue, String commandFilepath, String responseFilepath) {
        super("HNCServerThread");
        this.commandQueue = commandQueue;
        this.commandFilepath = commandFilepath;
        this.responseFilepath = responseFilepath;
    }
    
    public void run() {
    	String command = null;
    	while (running) {
	    	try {
		    	command = commandQueue.take();
		        
		        System.out.print("Processing command: " + command + "... ");
		        
		        String response = null;
		        RandomAccessFile responseRaf = new RandomAccessFile(responseFilepath, "r");
		        Character c = null;
		        while (c == null || '-' == c) {
		        	responseRaf.seek(0);
		    		c = (char) responseRaf.readByte();
		    		if (c == '-') {
		    			Thread.sleep(10);
		    		}
		        }
		        responseRaf.seek(0);
		        response = responseRaf.readLine();
		        int commandId = Integer.parseInt(response) + 1;
		        if (commandId > 10) {
		        	commandId = 1;
		        }
		        RandomAccessFile commandRaf = new RandomAccessFile(commandFilepath, "rwd");
		    	commandRaf.writeBytes("-" + new Integer(commandId).toString() + System.lineSeparator());
		    	commandRaf.writeBytes(command);
		    	commandRaf.setLength(commandRaf.getFilePointer());
		    	commandRaf.seek(0);
		    	commandRaf.writeBytes("+");
		    	commandRaf.close();
		        
		    	char signChar;
		    	boolean success = false;
		    	int counter = 0;
		    	while (!success) {
		    		counter++;
		    		if (counter > HNCServerWorker.MAX_ATTEMPTS) {
		    			System.out.println();
		    			System.err.println("Server did not process the request in time: " + command);
		    			break;
		    		}
		    		Thread.sleep(10);
		    		responseRaf.seek(0);
		    		signChar = (char) responseRaf.readByte();
		    		if (signChar == '+') {
		    			responseRaf.seek(0);
		    			response = responseRaf.readLine();
		    			if (commandId == Integer.parseInt(response)) {
		    				success = true;
		    			}
		    		}
		    	}
		    	if (success) {
		    		System.out.println("Done.");
		    	}
		    	responseRaf.close();
	    	} catch (InterruptedException e) {
	    		running = false;
	    	} catch (IOException e) {
				System.err.println("Failed to write command: " + command);
				e.printStackTrace();
			}
    	}
    }
}