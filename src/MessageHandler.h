#pragma once

// Installs a custom Qt message handler that silences specific known
// warnings from third-party libraries while forwarding everything
// else to the default handler.
void installMessageHandler();
