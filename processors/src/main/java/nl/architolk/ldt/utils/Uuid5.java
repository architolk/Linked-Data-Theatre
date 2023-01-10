/**
 * NAME     Uuid5.java
 * VERSION  1.25.0
 * DATE     2020-07-19
 *
 * Copyright 2012-2020
 *
 * This file is part of the Linked Data Theatre.
 *
 * The Linked Data Theatre is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Linked Data Theatre is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
 */
/**
 * DESCRIPTION
 * Creates a Uuid version 5 from a supplied uuid and a string
 *
 */
package nl.architolk.ldt.utils;

import java.nio.charset.Charset;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Objects;
import java.util.UUID;


public class Uuid5 {

  private static final Charset UTF8 = Charset.forName("UTF-8");
  private static final UUID NAMESPACE_DNS = UUID.fromString("6ba7b810-9dad-11d1-80b4-00c04fd430c8"); //Future feature
  private static final UUID NAMESPACE_URL = UUID.fromString("6ba7b811-9dad-11d1-80b4-00c04fd430c8");
  private static final UUID NAMESPACE_OID = UUID.fromString("6ba7b812-9dad-11d1-80b4-00c04fd430c8"); //Future feature
  private static final UUID NAMESPACE_X500 = UUID.fromString("6ba7b814-9dad-11d1-80b4-00c04fd430c8"); //Future feature

  public static String createURL(String name) throws NoSuchAlgorithmException {
    return nameUUIDFromNamespaceAndString(NAMESPACE_URL,name).toString();
  }

  public static String create(String namespace, String name) throws NoSuchAlgorithmException {
    return nameUUIDFromNamespaceAndString(UUID.fromString(namespace),name).toString();
  }

  private static UUID nameUUIDFromNamespaceAndString(UUID namespace, String name) throws NoSuchAlgorithmException {
      return nameUUIDFromNamespaceAndBytes(namespace, Objects.requireNonNull(name, "name == null").getBytes(UTF8));
  }

  private static UUID nameUUIDFromNamespaceAndBytes(UUID namespace, byte[] name) throws NoSuchAlgorithmException {
      MessageDigest md = MessageDigest.getInstance("SHA-1");
      md.update(toBytes(Objects.requireNonNull(namespace, "namespace is null")));
      md.update(Objects.requireNonNull(name, "name is null"));
      byte[] sha1Bytes = md.digest();
      sha1Bytes[6] &= 0x0f;  /* clear version        */
      sha1Bytes[6] |= 0x50;  /* set to version 5     */
      sha1Bytes[8] &= 0x3f;  /* clear variant        */
      sha1Bytes[8] |= 0x80;  /* set to IETF variant  */
      return fromBytes(sha1Bytes);
  }

  private static UUID fromBytes(byte[] data) {
      // Based on the private UUID(bytes[]) constructor
      long msb = 0;
      long lsb = 0;
      assert data.length >= 16;
      for (int i = 0; i < 8; i++)
          msb = (msb << 8) | (data[i] & 0xff);
      for (int i = 8; i < 16; i++)
          lsb = (lsb << 8) | (data[i] & 0xff);
      return new UUID(msb, lsb);
  }

  private static byte[] toBytes(UUID uuid) {
      // inverted logic of fromBytes()
      byte[] out = new byte[16];
      long msb = uuid.getMostSignificantBits();
      long lsb = uuid.getLeastSignificantBits();
      for (int i = 0; i < 8; i++)
          out[i] = (byte) ((msb >> ((7 - i) * 8)) & 0xff);
      for (int i = 8; i < 16; i++)
          out[i] = (byte) ((lsb >> ((15 - i) * 8)) & 0xff);
      return out;
  }
}
