# Implementation Journey: [Using Java in Skills]

This section introduces you to how to use Java in Agent Skills in a script way.

**Date added:** [04/16/2026]  
**Duration:** 10 min 
**Mode(s) Used:** *Advanced* mode

## Initial Goal

Create a Skill that executes Java to return a greeting.

---

## Basic Example. Step-by-Step Process

### Step 1: Install jbang

JBang (https://www.jbang.dev/) is a tool that lets you run Java code easily, without having to compile or download anything required, from the JVM to the libraries.

You can install jbang using `sdk`, `brew`, or `choco`:

```bash
sdk install jbang
brew install jbangdev/tap/jbang
choco install jbang
```

Or download it directly from https://www.jbang.dev/download.

**Outcome:**

JBang is installed on your computer.

### Step 2: Create Skill layout

Open IBM Bob and create the Skills directory `.bob/skills/greeting`.

Then, inside the `greeting` directory, create another directory named `scripts`, where we will put the Java code.
Also, inside the `greeting` directory, create an empty `SKILL.md` file.

**Outcome:** 

You created a skills structure to develop a Skill that uses Java.


### Step 3: Create the Java code

Inside the `scripts` directory, create a new file named `Hello.java` with the following content:

```java
public class Hello {
    public static void main(String args[]) {
        System.out.println("Aloha from Java");
 }
}
```

**Outcome:** 

A Java class that prints a message to the console.

### Step 4: Create the Skill

Let's create the Skill that executes this Java class.
Open the `SKILL.md` file and add the following content:

```md
----
name: greeting
description: Use this Greeting skill for greeting the user
----

## Greeting

This skill is used when the user requests a greeting.
You need to follow the next steps:

### Workflow

1. Run the following script:

\```bash
pwd
jbang ./scripts/Hello.java
\```

2. Use the output of the command as greeting
```

**Outcome:**

Skill is ready to use.

### Step 5: Prompt Bob

Go to Bob's chat and ask: "Send a greeting".

**Bob Response:**

Bob will ask for your permission to run the jbang command. You approve, and you'll see that the Java class runs and produces the output.
That's great, no verifications if Java is installed or not, or compiling the class or running `javac` and then  `java` with classpath. JBang takes care of everything.

## Dependencies Example. Step-by-Step Process

### Step 1: Create a new Java Class

Create a new Java class in the `scripts` directory with the name `HelloEmoji.java`.

In this class, we'll use the `com.vdurmont:emoji-java:5.1.0` Java library to produce an output using Emojis.
Adding a library is as easy as adding a comment with the `DEPS` keyword.

```java
//DEPS com.vdurmont:emoji-java:5.1.0

import com.vdurmont.emoji.EmojiParser;

public class HelloEmoji {
    public static void main(String[] args) {
        String msg = "Aloha :smiley:";
        System.out.println(EmojiParser.parseToUnicode(msg));
 } 
}
```

It is a normal Java class; JBang will automatically resolve the dependency and add it to the classpath, so it is no different from other Java classes, except that it now uses an external library.

Now edit the `SKILL.md` file, changing the JBang part to call the new class:

```bash
pwd
jbang ./scripts/HelloEmoji.java
```

### Step 2: Prompt Bob

Go to Bob's chat and ask: "Send a greeting".

**Bob Response:**

Bob will ask for your permission to run the jbang command. You approve, and you'll see that the Java class runs and returns the output with an emoji.

## Final Outcome

**What was achieved:**
- How to use Java in Skills
- JBang as a project to run Java
