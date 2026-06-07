Feature: Blob attachments and transclusion
  As a user who keeps images and PDFs alongside my notes
  I want to upload binary files and transclude them like any other note
  So that a diagram or PDF lives in one place but appears wherever I embed it

  # A blob is a strand whose content is binary. It shares all strand rules
  # (UUIDv7 id, unique case-insensitive title, backlinks) defined in
  # strand_common.feature, and is embedded with the same {{Title}} syntax as a
  # note. It differs from a note in that its content is binary (with a MIME
  # type), it is not edited as text, and it renders according to its type.
  # Where the bytes are stored is an implementation detail, not asserted here.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Uploading a file creates a transcludable blob
    When I upload the image "coffee-setup.png"
    Then a blob titled "coffee-setup.png" exists
    And the blob records its content type "image/png"

  Scenario: Transcluding an image renders it inline
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "My setup: {{coffee-setup.png}}"
    When I view the note "Gear"
    Then the rendered output embeds an image sourced from the blob "coffee-setup.png"
    And the embed is marked as coming from "coffee-setup.png"

  Scenario: Transcluding a PDF renders an inline viewer
    Given an uploaded file "manual.pdf" with content type "application/pdf"
    And a note titled "Machine" with body "Reference: {{manual.pdf}}"
    When I view the note "Machine"
    Then the rendered output embeds a PDF viewer for the blob "manual.pdf"

  Scenario: An unsupported type renders as a download link
    Given an uploaded file "data.zip" with content type "application/zip"
    And a note titled "Backup" with body "{{data.zip}}"
    When I view the note "Backup"
    Then the embed shows a download link for the blob "data.zip"
    And no inline preview is rendered

  Scenario: SVG is sanitized on upload and rendered inline
    Given a note titled "Brand" with body "{{logo.svg}}"
    When I upload an SVG "logo.svg" that contains a <script> element and an onload attribute
    And I view the note "Brand"
    Then the rendered output embeds the SVG inline
    And the embedded SVG contains no script elements
    And the embedded SVG contains no event-handler attributes

  Scenario: Transcluded blobs are read-only with a go-to-source action
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "{{coffee-setup.png}}"
    When I view the note "Gear"
    Then the embedded "coffee-setup.png" offers no inline editing
    And it offers a "go to source" action that opens the blob "coffee-setup.png"

  Scenario: A blob lists its embedders as backlinks
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "{{coffee-setup.png}}"
    And a note titled "Wishlist" with body "{{coffee-setup.png}}"
    When I view the blob "coffee-setup.png"
    Then the backlinks panel lists "Gear"
    And the backlinks panel lists "Wishlist"

  Scenario: Replacing a blob's content updates every embedding note
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "{{coffee-setup.png}}"
    When I replace the blob "coffee-setup.png" with a new image
    Then viewing the note "Gear" embeds the new image content

  Scenario: Renaming a blob updates transclusions that point to it
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "{{coffee-setup.png}}"
    When I rename the blob "coffee-setup.png" to "rig.png"
    And I view the note "Gear"
    Then the embed renders the image from the blob "rig.png"
    And there are no missing embeds in "Gear"

  Scenario: Deleting a blob shows a generic placeholder in embedders
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "{{coffee-setup.png}}"
    When I delete the blob "coffee-setup.png"
    And I view the note "Gear"
    Then the embed shows a "missing source: coffee-setup.png" placeholder
    And the placeholder does not claim whether the target was a note or an attachment

  Scenario: A file at the size limit is accepted
    When I upload a file "big.pdf" of 50 MB
    Then a blob titled "big.pdf" exists

  Scenario: A file over the size limit is rejected
    When I try to upload a file "huge.pdf" of 51 MB
    Then the upload is rejected with a "file too large" error
