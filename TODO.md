# Project Structure

## Editor

This is the top level class. It contains many subsections, which can be of various types, and controls the adding and removing of sections

## Section

This is the base class for sections, right now it's a bit text focus, that should get refactored. Sections should all have an updateElement method that controls updates to the dom and a render method that to render text

## Paragraph

Main section for text

## Range (rename to TextRange?)

Represents a selection within a Paragraph's text. start + length.

## Highlight

A Range extended with information about a tag to wrap content in for rendering


# Concepts
