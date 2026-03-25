ALTER TABLE "clients"
ADD COLUMN "phone" TEXT,
ADD COLUMN "firebase_uid" TEXT;

ALTER TABLE "clients"
ALTER COLUMN "pass_hash" DROP NOT NULL;

CREATE UNIQUE INDEX "clients_firebase_uid_key" ON "clients"("firebase_uid");
