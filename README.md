# TLS Client/Mutual-Auth with NGINX

Minimal project of client using mTLS (Mutual TLS authentication).
(Not entirely minimal since it uses JSON…)

The [configure](./configure.sh) script will generate all the necessary certificate/key pairs.
The [test](./test.sh) script will verify that the certificates are properly served and correctly verified by both client and server, and test for common errors.

The entire project can be exercised with a single command sequence:
```shell
just depends configure test clean
```
