/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.IOException;
import java.util.NoSuchElementException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.KeeperException.NoNodeException;
import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.ZooDefs;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.ACL;
import org.apache.zookeeper.data.Id;

public class ZooKeeperSetAcls {
    protected ZooKeeper zk;
    protected String host = "";
    protected MyCommandOptions cl = new MyCommandOptions();

    static void usage() {
        System.err.println("ZooKeeper -server host:port <path> <scheme:subject:perms[,scheme:subject:perms,...]> [<path> <acl> ...]");
    }

    /* Dummy Watcher */
    private class MyWatcher implements Watcher {
        public void process(WatchedEvent event) {
        }
    }

    static private int getPermFromString(String permString) {
        int perm = 0;
        for (int i = 0; i < permString.length(); i++) {
            switch (permString.charAt(i)) {
            case 'r':
                perm |= ZooDefs.Perms.READ;
                break;
            case 'w':
                perm |= ZooDefs.Perms.WRITE;
                break;
            case 'c':
                perm |= ZooDefs.Perms.CREATE;
                break;
            case 'd':
                perm |= ZooDefs.Perms.DELETE;
                break;
            case 'a':
                perm |= ZooDefs.Perms.ADMIN;
                break;
            default:
                System.err
                .println("Unknown perm type: " + permString.charAt(i));
            }
        }
        return perm;
    }

    static class MyPathWithACLs {
        private String path;
        private List<ACL> acls;

        public MyPathWithACLs(String path, List<ACL> acls) {
            this.path = path;
            this.acls = acls;
        }

        public String getPath() {
            return path;
        }

        public List<ACL> getACLs() {
            return acls;
        }
    }

    static class MyCommandOptions {
        private Map<String,String> options = new HashMap<String,String>();
        private List<MyPathWithACLs> pathsWithACLs = new ArrayList<MyPathWithACLs>();

        public MyCommandOptions() {
          options.put("server", "localhost:2181");
          options.put("timeout", "30000");
        }

        public String getOption(String opt) {
            return options.get(opt);
        }

        public List<MyPathWithACLs> getPathsWithACLs() {
            return pathsWithACLs;
        }

        public boolean parseOptions(String[] args) {
            List<String> argList = Arrays.asList(args);
            Iterator<String> it = argList.iterator();

            while (it.hasNext()) {
                String opt = it.next();
                if (opt.startsWith("-")) {
                    try {
                        if (opt.equals("-server")) {
                            options.put("server", it.next());
                        } else if (opt.equals("-timeout")) {
                            options.put("timeout", it.next());
                        } else {
                            System.err.println("Error: unknown option: " + opt);
                            return false;
                        }
                    } catch (NoSuchElementException e){
                        System.err.println("Error: no argument found for option "
                                + opt);
                        return false;
                    }

                    continue;
                }

                String path = opt;
                if (!it.hasNext()) {
                    System.err.println("Error: ACLs missing for path: " + path);
                    return false;
                }

                String aclarg = it.next();
                List<ACL> acls = parseACLs(aclarg);
                if (acls == null) {
                    System.err.println("Error: invalid ACL " + aclarg + " for path " + path);
                    return false;
                }

                pathsWithACLs.add(new MyPathWithACLs(opt, acls));
            }
            return true;
        }
    }

    public static void main(String args[])
    {
        ZooKeeperSetAcls main = new ZooKeeperSetAcls(args);
        System.exit(0);
    }

    public ZooKeeperSetAcls(String args[]) {
        if (!cl.parseOptions(args)) {
            System.exit(1);
        }

        Watcher watcher = new MyWatcher();
        System.out.println("Connecting to " + cl.getOption("server"));
        try {
            zk = new ZooKeeper(cl.getOption("server"),
                    Integer.parseInt(cl.getOption("timeout")),
                    watcher);
        } catch (IOException e){
            System.err.println("IOError: " + e.getMessage());
            System.exit(2);
        }

        for (MyPathWithACLs pwa: cl.getPathsWithACLs()) {
            try {
                zk.setACL(pwa.getPath(), pwa.getACLs(), -1);
            } catch (NoNodeException e){
                // if node doesn't exist yet, try to create it with the given
                // ACL
                try {
                    zk.create(pwa.getPath(), new byte[0], pwa.getACLs(),
                        CreateMode.PERSISTENT);
                } catch (InterruptedException f){
                    System.err.println("create interrupted: " +
                        f.getMessage());
                    System.exit(5);
                } catch (KeeperException f) {
                    System.err.println("create operation error: " +
                        f.getMessage());
                    System.exit(6);
                }
            } catch (InterruptedException e){
                System.err.println("setACL interrupted: " + e.getMessage());
                System.exit(3);
            } catch (KeeperException e){
                System.err.println("setACL operation error: " + e.getMessage());
                System.exit(4);
            }
        }
    }

    private static List<ACL> parseACLs(String aclString) {
        List<ACL> acl;
        String acls[] = aclString.split(",");
        acl = new ArrayList<ACL>();
        for (String a : acls) {
            int firstColon = a.indexOf(':');
            int lastColon = a.lastIndexOf(':');
            if (firstColon == -1 || lastColon == -1 || firstColon == lastColon) {
                System.err
                .println(a + " does not have the form scheme:id:perm");
                return null;
            }
            ACL newAcl = new ACL();
            newAcl.setId(new Id(a.substring(0, firstColon), a.substring(
                    firstColon + 1, lastColon)));
            newAcl.setPerms(getPermFromString(a.substring(lastColon + 1)));
            acl.add(newAcl);
        }
        return acl;
    }
}
