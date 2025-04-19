# Mcpixir Elixir Module Map

This document outlines the structure and responsibilities of the main modules in the Mcpixir Elixir project.

## Core Modules

- `Mcpixir` - Main entry point for the library
- `Mcpixir.Client` - Manages MCP servers and sessions
- `Mcpixir.Session` - Manages connections to MCP implementations
- `Mcpixir.Config` - Loads and manages configuration
- `Mcpixir.Logging` - Provides logging functionality

## Connectors

Connectors handle communication with MCP servers via different protocols:

- `Mcpixir.Connectors.Base` - Base behaviour for all connectors
- `Mcpixir.Connectors.HttpConnector` - HTTP-based connector
- `Mcpixir.Connectors.WebSocketConnector` - WebSocket-based connector
- `Mcpixir.Connectors.StdioConnector` - Standard IO-based connector

## Agents

Agents bridge between LLMs and MCP tools:

- `Mcpixir.Agents.Base` - Base behaviour for all agents
- `Mcpixir.Agents.MCPAgent` - Main agent implementation
- `Mcpixir.Agents.Prompts.SystemPromptBuilder` - Builds system prompts for agents
- `Mcpixir.Agents.Prompts.Templates` - Templates for agent prompts

## Adapters

Adapters convert between different formats:

- `Mcpixir.Adapters.LangChainAdapter` - Converts MCP tools to LangChain format

## Task Managers

Task managers handle different types of connections:

- `Mcpixir.TaskManagers.Base` - Base behaviour for all task managers
- `Mcpixir.TaskManagers.StdioManager` - Stdio-based task manager
- `Mcpixir.TaskManagers.WebSocketManager` - WebSocket-based task manager
- `Mcpixir.TaskManagers.SSEManager` - Server-Sent Events-based task manager

## Server Management

- `Mcpixir.ServerManager` - Manages MCP servers and their capabilities

## Project Configuration

- `mix.exs` - Project configuration
- `config/*.exs` - Environment-specific configuration
