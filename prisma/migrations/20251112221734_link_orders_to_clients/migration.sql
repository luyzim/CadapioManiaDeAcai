/*
  Warnings:

  - A unique constraint covering the columns `[name]` on the table `items` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "client_id" INTEGER;

-- CreateIndex
CREATE UNIQUE INDEX "items_name_key" ON "items"("name");

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;
